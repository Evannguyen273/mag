import itertools
import re
from func_timeout import func_timeout
import pandas as pd
from pandas.testing import assert_frame_equal, assert_series_equal
from sqlalchemy import create_engine, text
from utils.creds import db_creds_all
import time
import collections
LIKE_PATTERN = r"LIKE[\s\S]*'"
def deduplicate_columns(df: pd.DataFrame) -> pd.DataFrame:
    cols = df.columns.tolist()
    if len(cols) != len(set(cols)):
        duplicates = [
            item for item, count in collections.Counter(cols).items() if count > 1
        ]
        for dup in duplicates:
            indices = [i for i, x in enumerate(cols) if x == dup]
            for i in indices:
                cols[i] = f"{dup}_{i}"
        df.columns = cols
    return df

def find_bracket_indices(s: str, start_index: int = 0) -> "tuple[int, int]":
    start = s.find("{", start_index)
    end = s.find("}", start + 1)
    if start == -1 or end == -1:
        return (-1, -1)
    return (start, end)

def get_all_minimal_queries(query: str) -> "list[str]":
    """
    extrapolate all possible queries
    - split by semicolon. this is to accommodate queries where joins to other tables are also acceptable.
    - expand all column permutations if there are braces { } in it. eg:
    ```sql
        SELECT {user.id, user.name} FROM user;
    ```
    Would be expanded to:
    ```sql
        SELECT user.id FROM user;
        SELECT user.name FROM user;
        SELECT user.id, user.name FROM user;
    ```
    """
    queries = query.split(";")
    result_queries = []
    for query in queries:
        query = query.strip()
        if query == "":
            continue
        start, end = find_bracket_indices(query, 0)
        if (start, end) == (-1, -1):
            result_queries.append(query)
            continue
        else:
            # get all possible column subsets
            column_options = query[start + 1 : end].split(",")
            column_combinations = list(
                itertools.chain.from_iterable(
                    itertools.combinations(column_options, r)
                    for r in range(1, len(column_options) + 1)
                )
            )
            for column_tuple in column_combinations:
                left = query[:start]
                column_str = ", ".join(column_tuple)
                right = query[end + 1 :]
                # change group by size dynamically if necessary
                if right.find("GROUP BY {}"):
                    right = right.replace("GROUP BY {}", f"GROUP BY {column_str}")
                result_queries.append(left + column_str + right)
    return result_queries

# for escaping percent signs in regex matches
def escape_percent(match):
    # Extract the matched group
    group = match.group(0)
    # Replace '%' with '%%' within the matched group
    escaped_group = group.replace("%", "%%")
    # Return the escaped group
    return escaped_group

def normalize_table(
    df: pd.DataFrame, query_category: str, question: str, sql: str = None
) -> pd.DataFrame:
    """
    Normalizes a dataframe by:
    1. removing all duplicate rows
    2. sorting columns in alphabetical order
    3. sorting rows based on ORDER BY clause if present in SQL, otherwise using values from first column to last
    4. resetting index
    """
    # remove duplicate rows, if any
    df = df.drop_duplicates()

    # sort columns in alphabetical order of column names
    sorted_df = df.reindex(sorted(df.columns), axis=1)

    # check if SQL contains ORDER BY clause
    has_order_by = False
    if sql:
        order_by_pattern = re.compile(r'\bORDER\s+BY\b', re.IGNORECASE)
        has_order_by = bool(order_by_pattern.search(sql))

    if has_order_by:
        # determine which columns are in the ORDER BY clause of the sql generated, using regex
        pattern = re.compile(r"ORDER BY[\s\S]*", re.IGNORECASE)
        order_by_clause = re.search(pattern, sql)
        if order_by_clause:
            order_by_clause = order_by_clause.group(0)
            # get all columns in the ORDER BY clause, by looking at the text between ORDER BY and the next semicolon, comma, or parentheses
            pattern = re.compile(r"(?<=ORDER BY)(.*?)(?=;|$)", re.IGNORECASE)
            order_by_columns = re.findall(pattern, order_by_clause)
            order_by_columns = order_by_columns[0].split(',') if order_by_columns else []
            order_by_columns = [col.strip() for col in order_by_columns]

            # Process each column in the ORDER BY clause
            processed_columns = []
            ascending = []
            for col in order_by_columns:
                col_parts = col.split()
                col_name = col_parts[0].strip('`"').rsplit('.', 1)[-1]  # Remove table prefix if present
                processed_columns.append(col_name)
                # Check for DESC or ASC
                if len(col_parts) > 1 and col_parts[1].upper() == 'DESC':
                    ascending.append(False)
                else:
                    ascending.append(True)

            # Filter out columns that don't exist in the dataframe
            existing_columns = [col for col in processed_columns if col in sorted_df.columns]
            existing_ascending = [asc for col, asc in zip(processed_columns, ascending) if col in sorted_df.columns]

            # If we have valid columns to sort by
            if existing_columns:
                sorted_df = sorted_df.sort_values(by=existing_columns, ascending=existing_ascending)

                # Reorder columns to put ORDER BY columns last
                other_columns = [col for col in sorted_df.columns if col not in existing_columns]
                sorted_df = sorted_df[other_columns + existing_columns]

    else:
        # If no ORDER BY, sort rows using values from first column to last
        sorted_df = sorted_df.sort_values(by=list(sorted_df.columns))

    # reset index
    sorted_df = deduplicate_columns(sorted_df)
    sorted_df = sorted_df.reset_index(drop=True)
    return sorted_df



def compare_df(
    df_gold: pd.DataFrame,
    df_gen: pd.DataFrame,
    query_category: str,
    question: str,
    query_gold: str = None,
    query_gen: str = None,
) -> bool:
    """
    Compares two dataframes and returns True if they contain the same data, regardless of row order or duplicates.
    query_gold and query_gen are the original queries that generated the respective dataframes.
    """
    # Normalize the dataframes
    df_gold = normalize_table(df_gold, query_category, question, query_gold)
    df_gen = normalize_table(df_gen, query_category, question, query_gen)

    # Check if the dataframes have the same columns
    if set(df_gold.columns) != set(df_gen.columns):
        return False

    # Ensure the columns are in the same order
    df_gold = df_gold.reindex(sorted(df_gold.columns), axis=1)
    df_gen = df_gen.reindex(sorted(df_gen.columns), axis=1)

    # Replace NaNs with a specific value
    df_gold = df_gold.fillna(-99999)
    df_gen = df_gen.fillna(-99999)

    # Convert dataframes to sets of tuples for comparison
    set_gold = set(map(tuple, df_gold.itertuples(index=False, name=None)))
    set_gen = set(map(tuple, df_gen.itertuples(index=False, name=None)))

    # Compare the sets
    return set_gold == set_gen


def subset_df(
    df_sub: pd.DataFrame,
    df_super: pd.DataFrame,
    query_category: str,
    question: str,
    query_super: str = None,
    query_sub: str = None,
    verbose: bool = False,
) -> bool:
    """
    Checks if df_sub is a subset of df_super.
    """
    if df_sub.empty:
        return False  # handle cases for empty dataframes

    # make a copy of df_super so we don't modify the original while keeping track of matches
    df_super_temp = df_super.copy(deep=True)
    matched_columns = []
    df_sub = deduplicate_columns(df_sub)
    df_super_temp = deduplicate_columns(df_super_temp)
    for col_sub_name in df_sub.columns:
        col_match = False
        for col_super_name in df_super_temp.columns:
            col_sub = df_sub[col_sub_name].sort_values().reset_index(drop=True)
            col_super = (
                df_super_temp[col_super_name].sort_values().reset_index(drop=True)
            )

            try:
                assert_series_equal(
                    col_sub, col_super, check_dtype=False, check_names=False
                )
                col_match = True
                matched_columns.append(col_super_name)
                # remove col_super_name to prevent us from matching it again
                df_super_temp = df_super_temp.drop(columns=[col_super_name])
                break
            except AssertionError:
                continue

        if not col_match:
            if verbose:
                print(f"no match for {col_sub_name}")
            return False

    df_sub_normalized = normalize_table(df_sub, query_category, question, query_sub)

    # get matched columns from df_super, and rename them with columns from df_sub, then normalize
    df_super_matched = df_super[matched_columns].rename(
        columns=dict(zip(matched_columns, df_sub.columns))
    )
    df_super_matched = normalize_table(
        df_super_matched, query_category, question, query_super
    )

    try:
        assert_frame_equal(df_sub_normalized, df_super_matched, check_dtype=False)
        return True
    except AssertionError:
        return False
    
    
    
    import json
from concurrent.futures import ThreadPoolExecutor, as_completed
import copy
import os

from eval.eval import compare_query_results
import pandas as pd
from psycopg2.extensions import QueryCanceledError
from query_generators.openai import OpenAIQueryGenerator
from tqdm import tqdm
from utils.questions import prepare_questions_df
from utils.creds import db_creds_all
from utils.reporting import upload_results


def run_openai_eval(args):
    # get params from args
    questions_file_list = args.questions_file
    prompt_file_list = args.prompt_file
    output_file_list = args.output_file
    num_questions = args.num_questions
    k_shot = args.k_shot
    db_type = args.db_type
    cot_table_alias = args.cot_table_alias

    for questions_file, prompt_file, output_file in zip(
        questions_file_list, prompt_file_list, output_file_list
    ):
        print(f"Using prompt file {prompt_file}")
        # get questions
        print("Preparing questions...")
        print(
            f"Using {'all' if num_questions is None else num_questions} question(s) from {questions_file}"
        )
        question_query_df = prepare_questions_df(
            questions_file, db_type, num_questions, k_shot, cot_table_alias
        )
        input_rows = question_query_df.to_dict("records")
        output_rows = []
        with ThreadPoolExecutor(args.parallel_threads) as executor:
            # for each query in the csv, generate a query using the generator asynchronously
            futures = []
            for row in input_rows:
                # get db creds for each row's db_name
                db_name = row["db_name"]
                db_creds = db_creds_all[row["db_type"]]

                qg = OpenAIQueryGenerator(
                    db_creds=copy.deepcopy(db_creds),
                    db_name=db_name,
                    db_type=db_type,
                    model=args.model,
                    prompt_file=prompt_file,
                    timeout=args.timeout_gen,
                    use_public_data=not args.use_private_data,
                    verbose=args.verbose,
                )

                generated_query_fut = executor.submit(
                    qg.generate_query,
                    question=row["question"],
                    instructions=row["instructions"],
                    k_shot_prompt=row["k_shot_prompt"],
                    glossary=row["glossary"],
                    table_metadata_string=row["table_metadata_string"],
                    prev_invalid_sql=row["prev_invalid_sql"],
                    prev_error_msg=row["prev_error_msg"],
                    cot_instructions=row["cot_instructions"],
                    columns_to_keep=args.num_columns,
                    shuffle=args.shuffle_metadata,
                )
                futures.append(generated_query_fut)

            total_tried = 0
            total_correct = 0
            for f in (pbar := tqdm(as_completed(futures), total=len(futures))):
                total_tried += 1
                i = futures.index(f)
                row = input_rows[i]
                result_dict = f.result()
                query_gen = result_dict["query"]
                reason = result_dict["reason"]
                err = result_dict["err"]
                table_metadata_string = result_dict["table_metadata_string"]
                # save custom metrics
                if "latency_seconds" in result_dict:
                    row["latency_seconds"] = result_dict["latency_seconds"]
                if "tokens_used" in result_dict:
                    row["tokens_used"] = result_dict["tokens_used"]
                row["generated_query"] = query_gen
                row["reason"] = reason
                row["error_msg"] = err
                row["table_metadata_string"] = table_metadata_string
                # save failures into relevant columns in the dataframe
                if "GENERATION ERROR" in err:
                    row["error_query_gen"] = 1
                elif "EXECUTION ERROR" in err:
                    row["error_db_exec"] = 1
                elif "TIMEOUT" in err:
                    row["timeout"] = 1
                else:
                    expected_query = row["query"]
                    db_name = row["db_name"]
                    db_type = row["db_type"]
                    question = row["question"]
                    query_category = row["query_category"]
                    table_metadata_string = row["table_metadata_string"]
                    exact_match = correct = 0
                    db_creds = db_creds_all[db_type]
                    # try executing the queries and compare the results if they succeed
                    try:
                        exact_match, correct = compare_query_results(
                            query_gold=expected_query,
                            query_gen=query_gen,
                            db_name=db_name,
                            db_type=db_type,
                            db_creds=db_creds,
                            timeout=args.timeout_exec,
                            question=question,
                            query_category=query_category,
                            table_metadata_string=table_metadata_string,
                            decimal_points=args.decimal_points,
                        )
                        row["exact_match"] = int(exact_match)
                        row["correct"] = int(correct)
                        row["error_msg"] = ""
                        if correct:
                            total_correct += 1
                    except QueryCanceledError as e:
                        row["timeout"] = 1
                        row["error_msg"] = f"QUERY EXECUTION TIMEOUT: {e}"
                    except Exception as e:
                        row["error_db_exec"] = 1
                        row["error_msg"] = f"QUERY EXECUTION ERROR: {e}"
                output_rows.append(row)
                pbar.set_description(
                    f"Correct so far: {total_correct}/{total_tried} ({100*total_correct/total_tried:.2f}%)"
                )
        output_df = pd.DataFrame(output_rows)
        output_df = output_df.sort_values(by=["db_name", "query_category", "question"])
        if "prompt" in output_df.columns:
            del output_df["prompt"]
        # get num rows, mean correct, mean error_db_exec for each query_category
        agg_stats = (
            output_df.groupby("query_category")
            .agg(
                num_rows=("db_name", "count"),
                mean_correct=("correct", "mean"),
                mean_error_db_exec=("error_db_exec", "mean"),
            )
            .reset_index()
        )
        print(agg_stats)
        # get directory of output_file and create if not exist
        output_dir = os.path.dirname(output_file)
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
        output_df.to_csv(output_file, index=False, float_format="%.2f")

        # get average rate of correct results
        avg_subset = output_df["correct"].sum() / len(output_df)
        print(f"Average correct rate: {avg_subset:.2f}")

        results = output_df.to_dict("records")

        # upload results
        with open(prompt_file, "r") as f:
            prompt = f.read()
        if args.upload_url is not None:
            upload_results(
                results=results,
                url=args.upload_url,
                runner_type="openai",
                prompt=prompt,
                args=args,
            )
