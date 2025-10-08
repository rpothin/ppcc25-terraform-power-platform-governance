-- ==============================================================================
-- Script Name: create-demo-table.sql
-- Purpose: Create demo table and sample data for PPCC25 SQL Server demo
-- Usage: Execute in Azure Portal Query Editor after SQL Server deployment
-- ==============================================================================
-- This script creates the Customers table with sample data for testing
-- Power Platform SQL Server connector connectivity through private endpoints.
--
-- Authentication: Uses your Entra ID identity (automatic in Azure Portal)
-- Prerequisites: SQL Server and demo-db must be deployed first
-- ==============================================================================

-- Create demo table for Power Platform testing
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    Company NVARCHAR(100),
    Region NVARCHAR(50) DEFAULT 'Canada',
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
);

-- Insert sample customer data for demo
INSERT INTO Customers (FirstName, LastName, Email, Company, Region)
VALUES 
    ('Alice', 'Johnson', 'alice.johnson@contoso.com', 'Contoso Ltd', 'Canada Central'),
    ('Bob', 'Smith', 'bob.smith@fabrikam.com', 'Fabrikam Inc', 'Canada East'),
    ('Carol', 'Williams', 'carol.williams@northwind.com', 'Northwind Traders', 'Canada Central'),
    ('David', 'Brown', 'david.brown@adventure-works.com', 'Adventure Works', 'Canada East'),
    ('Eve', 'Davis', 'eve.davis@wide-world.com', 'Wide World Importers', 'Canada Central');

-- Verify data insertion
SELECT * FROM Customers ORDER BY CustomerID;

-- ==============================================================================
-- Expected Results:
-- - Table created: Customers
-- - Records inserted: 5 customer records
-- - Query returns: 5 rows with CustomerID 1-5
--
-- Next Steps:
-- 1. Verify query shows 5 customer records
-- 2. Open Power Automate in your demo environment
-- 3. Create SQL Server connector with "Microsoft Entra ID Integrated" auth
-- 4. Test connectivity by querying the Customers table
-- ==============================================================================
