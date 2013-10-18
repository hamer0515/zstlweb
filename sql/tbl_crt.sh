#!/bin/bash

db2 connect to $DB_NAME user $DB_USER using $DB_PASS;
db2 set current schema $DB_SCHEMA;


for file in `ls *.sql`; do
  echo $file;
  db2 -tvf $file;
done

