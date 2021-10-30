import csv
from os import path
import argparse
import subprocess

parser = argparse.ArgumentParser(
    usage="Create table and efficiently import CSV file into PostgreSQL database with COPY instruction.",
    epilog="All values are casted has TEXT")

parser.add_argument('csvfile', help='Path to csv file')
parser.add_argument('--delimiter', '-d', help='Columns delimiter (default : tab)', default='\t')
parser.add_argument('--pg', help='Connection string. Exemple "service=myservice" or "host=localhost dbname=mydb"')
parser.add_argument('--table', '-t', help='The table name (default : csv file name)', required=False, default=None)
parser.add_argument('--schema', '-s', help='The schema name', required=False, default=None)
parser.add_argument('--preserve-col-name', help='Do not lower columns names', dest='preserve_col_name', default=False,
                    action='store_true')
parser.add_argument('--dry', help='Just display the CREATE TABLE command', default=False, action='store_true')
parser.add_argument('--create-only', '--skip-copy', help='Do not make COPY command, only table creation',
                    dest='create_only', default=False, action='store_true')

parser.add_argument('--drop', help='Drop table if exists. CAUTION : POSSIBLE DATA LOSS !', default=False,
                    action='store_true')  # not implemented TODO  ?
parser.add_argument('--skip-create', help='Assuming table is already created, add reccords to existings',
                    action='store_true')  # not implemented

args = parser.parse_args()

csv_file_name = args.csvfile
table_name = args.table or path.splitext(path.basename(csv_file_name))[0]
schema_name = args.schema
connection_string = args.pg
lower_col_name = not args.preserve_col_name
delimiter = args.delimiter


def escaped_full_table_name(t_name, s_name=None):
    if not s_name or s_name.strip() == '':
        return '"{}"'.format(t_name)
    else:
        return '"{}"."{}"'.format(s_name, t_name)


def create_table_query(csv_file_path, t_name, s_name=None):
    """Extract col names from CSV, and generate an SQL instruction 
    """
    with open(csv_file_path) as csvfile:
        reader = csv.reader(csvfile, delimiter=delimiter)
        headers = next(reader)
    if lower_col_name:
        cols = ['"' + x.lower() + '" text' for x in headers]
    else:
        cols = ['"' + x + '" text' for x in headers]
    return "CREATE TABLE {} ( {} ) ;".format(
        escaped_full_table_name(t_name, s_name),
        ', \n'.join(cols))


if __name__ == '__main__':
    creation_table = create_table_query(csv_file_name, table_name)

    cmd = ["psql", connection_string, "--single-transaction"]
    if connection_string is None:
        del cmd[1]
    sql_command = ["-c", creation_table]  # Creation instruction
    copy_sql = "COPY {} FROM '{}' CSV HEADER DELIMITER '{}';".format(
        escaped_full_table_name(table_name, schema_name), csv_file_name,
        delimiter)  # TODO prise en charge correct du schema

    if not args.create_only:
        sql_command = sql_command + ["-c", copy_sql]  # Add copy instruction

    if not args.dry:
        subprocess.run(cmd + sql_command)
    else:
        print(creation_table)
        if not args.create_only:
            print('\n')
            print(copy_sql)
