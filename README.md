# Customer Portal Case Management

A Salesforce Lightning Web Component solution that allows community users to create, view, and manage support cases through a customer portal interface.

## Project Overview

This project provides a streamlined case management experience for community/portal users, allowing them to:

- Submit new support cases with product, type, and priority specifications
- View their existing cases with status and deadline information
- Add comments to ongoing cases 
- Track resolution progress

The solution is built using Lightning Web Components, ensuring a responsive and modern user experience within Salesforce Communities.

## Features

### Case Submission Form
- User-friendly interface for submitting new support cases
- Dynamic picklist values for Product, Type, and Priority fields
- Form validation to ensure complete case information
- Success/error notifications using toast messages

### Case Management
- View list of all cases associated with the current portal user
- Sort and filter capabilities
- Case detail view with full information and comments
- Ability to add comments to existing cases

### Security
- Record access respects Salesforce sharing rules
- User authentication and validation ensures users can only see their own cases
- "with sharing" enforcement throughout Apex code

## Component Structure

### Apex Classes
- `CaseController.cls`: Handles all case-related operations including:
  - Creating new cases
  - Retrieving case lists for the current user
  - Fetching detailed case information
  - Adding comments to cases

### Lightning Web Components
- `caseCaptureForm`: Provides the interface for submitting new cases
  - Dynamically loads picklist values
  - Handles form submission and validation
  - Provides feedback on submission status

## Technical Implementation

### Apex Controller

The `CaseController` class provides four main methods:
1. `createCase`: Creates a new case from form data and associates it with the current user's contact
2. `getMyCases`: Retrieves all cases associated with the current user
3. `getCaseDetails`: Gets detailed information for a specific case, including comments
4. `addCaseComment`: Adds a comment to an existing case

### Lightning Web Component

The case capture form component:
1. Loads picklist values for Type, Priority, and Product fields dynamically
2. Maintains form state with two-way binding
3. Handles form submission with loading state management
4. Provides error handling and success notifications
5. Emits a custom event when a case is created successfully

## Installation

### Prerequisites
- Salesforce org with Communities enabled
- Community Builder access
- API version 57.0 or higher

### Deployment Steps

1. Deploy the Apex classes using SFDX:
   ```
   sfdx force:source:deploy -p force-app/main/default/classes
   ```

2. Deploy the Lightning Web Components:
   ```
   sfdx force:source:deploy -p force-app/main/default/lwc
   ```

3. Add the components to your Community pages:
   - Edit the Community page in Community Builder
   - Drag the LWC components to the desired locations
   - Save and publish your Community

### Configuration

1. Ensure the Community user profile has access to:
   - Case object and relevant fields
   - CaseComment object
   - The deployed Apex classes

2. Custom field setup:
   - Ensure the `Product__c` custom field exists on the Case object
   - Configure any additional custom fields referenced in the components

## Usage

### Creating a Case
1. Navigate to the case submission form
2. Fill in all required fields
3. Click "Submit Case"
4. A confirmation message will appear upon successful submission

### Viewing Cases
1. Navigate to the case list view
2. Click on a case number to view details
3. Case details page will show all information including comments
4. Add new comments using the comment form

## Development Notes

- The components use `with sharing` to respect Salesforce sharing rules
- Error handling is implemented throughout the code
- The design follows Salesforce Lightning Design System patterns
- Record access is verified for all operations to ensure data security

## Related Components

This repository is part of a larger Community portal solution. Related components include:
- Knowledge Base Articles browser
- Account and Contact management
- Product registration
