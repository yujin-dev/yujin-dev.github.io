## [23.02.27]
```
TypeError: dict is not a sequence
```
- reason ?  SQLAlchemy expects the % to be a parameter of type ‘format’(Python string formatting) 
- solution ? Use "%%" instead of "%" in your queries
    ```
    # If you're using SQLAlchemy:
    # Use "%%" instead of "%" in your queries, because
    # a single "%" is used in Python string formatting.

    # Alternatively escape the SQL properly with sqlalchemy.text(...):
    engine.execute(sqlalchemy.text(sql_query))
    ```
- [SOLVE TYPEERROR: ‘DICT’ OBJECT DOES NOT SUPPORT INDEXING WHEN RUNNING SQL QUERIES IN PYTHON](https://www.roelpeters.be/solve-typeerror-dict-object-does-not-support-indexing-when-running-sql-queries-in-python/)