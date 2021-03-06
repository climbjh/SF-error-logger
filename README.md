# Salesforce Error Logger
#### Developed by: Evan Matthews, August 2021

This easy-to-implement utility can be dropped into any SalesForce Org to begin
logging and tracking errors that occure throughout the Apex landscape.

To implement this tool, simply download the package of files and copy/paste them into
the appropriate folders in your SF Org codebase.  (ie. all Apex classes/meta > 'classes' folder, custom Error_Log__c object > 'objects' folder)

##### What's Included:

 * The ErrorLogging and ErrorHelper classes which create the logs
 * The Error_Log__c custom object, which has custom list views for past 24 hours and past 7 days
 * DeleteErrorLogBatch schedulable class for regular purge of logs
 * An "Error Logs" custom tab for use in any app
 * Test classes with 100% coverage for all Apex classes


 Once installed, this package should allow tracking for any individual Exception or bulk DML failed operations.


 ### ErrorLogging Class Usage

 The methods in this class cover both individual exceptions and bulk failures.  Use the .basicError()
 method to catch errors within most Apex code.  To use for basic errors:

```
try {
    // your operation
} catch (Exception e) {
    ErrorLogging.basicError(e);
}
```

If you are wanting to catch errors in a bulk DML operation, you can do that in one of two ways.  To
capture errors and create one log per error with a list of all records that failed on that error, use:

```
Database.SaveResult[] sr = Database.insert(recordList);
ErrorLogging.resultsByError(sr);
```

If you want to capture all errors in one log with associated IDs or indexes (depending on operation),
use the .resultsByID() method:

```
Database.UpsertResult[] ur = Database.upsert(recordList);
ErrorLogging.resultsByID(ur);
```