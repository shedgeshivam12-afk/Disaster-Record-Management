# Maharashtra Disaster Management System
# Beginner-friendly Python + MySQL program
# Python performs simple rule-based risk scoring.
# MySQL stores and retrieves the information.

import mysql.connector
from datetime import datetime

# 1. CONNECT TO MYSQL DATABASE

db = mysql.connector.connect(
    host="localhost",
    user="jay",
    password="jay1",  # Replace with your MySQL password
    database="maharashtra_disaster_db"
)

cursor = db.cursor()


# 2. DISPLAY ALL DISTRICTS

def show_districts():
    cursor.execute("SELECT district_id, district_name FROM districts ORDER BY district_name")
    rows = cursor.fetchall()

    print("\n--- MAHARASHTRA DISTRICTS ---")
    for row in rows:
        print(row[0], "-", row[1])


# 3. DISPLAY TALUKAS OF A SELECTED DISTRICT

def show_talukas():
    show_districts()
    district_id = int(input("\nEnter district ID: "))

    cursor.execute(
        "SELECT taluka_id, taluka_name FROM talukas WHERE district_id = %s ORDER BY taluka_name",
        (district_id,)
    )
    rows = cursor.fetchall()

    print("\n--- TALUKAS ---")
    for row in rows:
        print(row[0], "-", row[1])


# 4. DISPLAY DISASTER TYPES

def show_disaster_types():
    cursor.execute("SELECT disaster_type_id, disaster_name FROM disaster_types ORDER BY disaster_name")
    rows = cursor.fetchall()

    print("\n--- DISASTER TYPES ---")
    for row in rows:
        print(row[0], "-", row[1])


# 5. SIMPLE RISK SCORE CALCULATION
# This is a basic demonstration rule, not an official emergency risk standard.

def calculate_risk(severity, affected, injured, missing, deaths):
    severity_points = {
        "LOW": 10,
        "MEDIUM": 25,
        "HIGH": 40,
        "CRITICAL": 55
    }

    score = severity_points[severity]
    score = score + min(20, affected // 50)
    score = score + min(10, injured // 10)
    score = score + min(10, missing // 5)
    score = score + min(15, deaths * 3)

    if score > 100:
        score = 100

    if score < 30:
        category = "LOW"
    elif score < 50:
        category = "MEDIUM"
    elif score < 75:
        category = "HIGH"
    else:
        category = "CRITICAL"

    return score, category


# 6. REGISTER A NEW DISASTER INCIDENT

def add_incident():
    show_districts()
    district_id = int(input("\nEnter district ID: "))

    cursor.execute(
        "SELECT taluka_id, taluka_name FROM talukas WHERE district_id = %s ORDER BY taluka_name",
        (district_id,)
    )
    taluka_rows = cursor.fetchall()

    taluka_id = None
    if taluka_rows:
        print("\nTalukas:")
        for row in taluka_rows:
            print(row[0], "-", row[1])
        taluka_choice = input("Enter taluka ID (or press Enter to skip): ")
        if taluka_choice.strip() != "":
            taluka_id = int(taluka_choice)

    show_disaster_types()
    disaster_type_id = int(input("\nEnter disaster type ID: "))

    incident_code = input("Enter a unique incident code (example: MH-2026-001): ")
    incident_date = input("Enter incident date and time (YYYY-MM-DD HH:MM:SS): ")

    print("\nSeverity: LOW / MEDIUM / HIGH / CRITICAL")
    severity = input("Enter severity: ").strip().upper()
    if severity not in ["LOW", "MEDIUM", "HIGH", "CRITICAL"]:
        print("Invalid severity. Incident not saved.")
        return

    affected = int(input("Number of affected people: "))
    injured = int(input("Number of injured people: "))
    missing = int(input("Number of missing people: "))
    deaths = int(input("Number of deaths: "))
    description = input("Short incident description: ")
    reported_by = input("Reported by: ")

    # Save incident in MySQL
    incident_query = """
        INSERT INTO disaster_incidents
        (incident_code, district_id, taluka_id, disaster_type_id,
         incident_date, severity, affected_people, injured_people,
         missing_people, deaths, description, incident_status, reported_by)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """

    incident_values = (
        incident_code, district_id, taluka_id, disaster_type_id,
        incident_date, severity, affected, injured, missing,
        deaths, description, "REPORTED", reported_by
    )

    cursor.execute(incident_query, incident_values)
    incident_id = cursor.lastrowid

    # Calculate and save risk assessment
    score, category = calculate_risk(severity, affected, injured, missing, deaths)

    factors = (
        "Severity=" + severity
        + "; Affected=" + str(affected)
        + "; Injured=" + str(injured)
        + "; Missing=" + str(missing)
        + "; Deaths=" + str(deaths)
    )

    cursor.execute(
        "INSERT INTO risk_assessments (incident_id, risk_score, risk_category, factors_used) "
        "VALUES (%s, %s, %s, %s)",
        (incident_id, score, category, factors)
    )

    db.commit()

    print("\nIncident saved successfully.")
    print("Incident ID:", incident_id)
    print("Risk Score:", score, "/ 100")
    print("Risk Category:", category)


# 7. VIEW ALL DISASTER INCIDENTS

def view_incidents():
    query = """
        SELECT i.incident_id, i.incident_code, d.district_name,
               dt.disaster_name, i.severity, i.incident_status,
               r.risk_score, r.risk_category
        FROM disaster_incidents i
        JOIN districts d ON i.district_id = d.district_id
        JOIN disaster_types dt ON i.disaster_type_id = dt.disaster_type_id
        LEFT JOIN risk_assessments r ON i.incident_id = r.incident_id
        ORDER BY i.incident_id DESC
    """

    cursor.execute(query)
    rows = cursor.fetchall()

    print("\n--- DISASTER INCIDENTS ---")
    for row in rows:
        print(row)


# 8. VIEW AVAILABLE RESCUE TEAMS

def show_available_teams():
    query = """
        SELECT team_id, team_name, district_id, team_size, team_status
        FROM rescue_teams
        WHERE team_status = 'AVAILABLE'
        ORDER BY team_name
    """

    cursor.execute(query)
    rows = cursor.fetchall()

    print("\n--- AVAILABLE RESCUE TEAMS ---")
    if len(rows) == 0:
        print("No team records found. Add verified team details to MySQL first.")
    else:
        for row in rows:
            print(row)


# 9. VIEW RESOURCE STOCK

def show_resource_stock():
    query = """
        SELECT rc.centre_name, r.resource_name,
               rs.quantity_available, r.unit_name
        FROM resource_stock rs
        JOIN resource_centres rc ON rs.centre_id = rc.centre_id
        JOIN resources r ON rs.resource_id = r.resource_id
        ORDER BY rc.centre_name, r.resource_name
    """

    cursor.execute(query)
    rows = cursor.fetchall()

    print("\n--- RESOURCE STOCK ---")
    if len(rows) == 0:
        print("No stock records found. Add verified centre and stock details first.")
    else:
        for row in rows:
            print(row)


# 10. MAIN MENU

try:
    print("Connected to Maharashtra Disaster Management Database.")

    while True:
        print("\n========== MAIN MENU ==========")
        print("1. View districts")
        print("2. View talukas")
        print("3. View disaster types")
        print("4. Register new disaster incident")
        print("5. View disaster incidents and risk scores")
        print("6. View available rescue teams")
        print("7. View resource stock")
        print("0. Exit")

        choice = input("Enter your choice: ")

        if choice == "1":
            show_districts()
        elif choice == "2":
            show_talukas()
        elif choice == "3":
            show_disaster_types()
        elif choice == "4":
            add_incident()
        elif choice == "5":
            view_incidents()
        elif choice == "6":
            show_available_teams()
        elif choice == "7":
            show_resource_stock()
        elif choice == "0":
            print("Thank you. Program closed.")
            break
        else:
            print("Invalid choice. Please try again.")

except mysql.connector.Error as error:
    print("MySQL error:", error)
    db.rollback()

except ValueError:
    print("Please enter valid numeric values where required.")
    db.rollback()

finally:
    cursor.close()
    db.close()
    print("Database connection closed.")
