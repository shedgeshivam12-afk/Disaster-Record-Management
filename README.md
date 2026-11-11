# Disaster Management System

A Python and MySQL-based project for maintaining disaster-related
records and viewing operational information.

## Project Overview

The system connects a Python application to a MySQL database. It
provides a menu-driven interface for working with disaster-management
information.

## Features

-   Incident reporting and viewing
-   View available rescue teams
-   View resource stock at resource centres
-   MySQL database for storing project records

> **Note:** This README describes the features tested in the current
> project. Add details for any other modules that are present in your
> final code.

## Technology Used

-   **Programming language:** Python
-   **Database:** MySQL
-   **Database tool:** MySQL Workbench
-   **Code editor:** Visual Studio Code

## Project Files

-   `dm.py` --- Python application
-   `maharashtra_disaster_management_simple_complete.sql` --- SQL script
    to create the database and tables
-   `maharashtra_disaster_db.sql` --- Exported database backup (if
    included)

## Requirements

-   Python 3
-   MySQL Server
-   MySQL Workbench (recommended)
-   Python MySQL connector package

Install the connector if it is not already installed:

``` bash
pip install mysql-connector-python
```

## Database Setup

1.  Open MySQL Workbench and connect to your MySQL Server.
2.  Open and run `maharashtra_disaster_management_simple_complete.sql`
    to create the database and tables.
3.  If you are using the exported backup instead, import
    `maharashtra_disaster_db.sql` through **Server → Data Import**.
4.  Make sure the database name and connection details in `dm.py` match
    your local MySQL setup.

**Important:** Do not upload real database passwords. Keep your MySQL
username/password private and configure them locally in your Python file
or a separate local configuration file.

## Run the Project

1.  Open the project folder in Visual Studio Code.
2.  Open the VS Code terminal.
3.  Run:

``` bash
python dm.py
```

4.  Follow the menu displayed in the terminal.

## Demo Data

The project may contain sample/demo records used for testing, such as a
demo incident, rescue team, resource centre, and resource stock. These
are fictional test records, not real emergency information.

## Author

Add your name and academic details here before submitting the project.

## License

This project is intended for academic and learning purposes.
