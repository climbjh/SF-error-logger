/*
Developer: Evan Matthews <evan.matthews@callawaycloudconsulting.com>
Description:
    A ulitity class developed to create error logs from various exceptions that occur
    throughout the Apex landscape of any Org.  Can be dropped into an org along with the proper
    meta and custom object Error_Log__c files.  Utilizes ErrorHelper class to perform some tasks
    for error handling.
*/
public with sharing class ErrorLogging {

    // process a default exception and add it to the custom Error Log object
    public static Error_Log__c basicError(Exception e, String affectedArea) {
        Error_Log__c newLog = new Error_Log__c();
        newLog.Type__c = e.getTypeName();
        newLog.Message__c = e.getMessage();
        newLog.Stack_Trace__c = e.getStackTraceString();
        newLog.Location__c = e.getStackTraceString().split(':')[0];
        newLog.Affected_Area__c = affectedArea;
        insert newLog;
        return newLog;
    }

    // process a Database SaveResult error array and log to the custom Error Log object. Sorted by index
    public static Error_Log__c resultsByID(Database.SaveResult[] srList) {

        Error_Log__c log = new Error_Log__c();
        String[] msgList = new String[]{};
        String[] fieldsList = new String[]{};
        String[] statusList = new String[]{};

        for (Integer i=0;i<srList.size();i++) {
            if (!srList[i].isSuccess()) {
                for (Database.Error err : srList[i].getErrors()) {
                    msgList.add('index ['+i+']: ' + err.getMessage()+'; '+ '\n');
                    statusList.add('index ['+i+']: ' + err.getStatusCode()+'; '+ '\n');
                    fieldsList.add('index ['+i+']: ' + err.getFields()+'; '+ '\n');
                }
            }
        }

        log.Message__c = String.join(msgList,'');
        log.Status_Code__c = String.join(statusList,'');
        log.Affected_Fields__c = String.join(fieldsList,'');
        log.Type__c = 'Batch Insert/Update Errors';

        insert log;
        return log;
    }

    // process a Database UpsertResult error array and log to the custom Error Log object.  Sorted by ID
    public static Error_Log__c resultsByID(Database.UpsertResult[] urList, List<SObject> sObjects) {
        Error_Log__c log = new Error_Log__c();
        String[] msgList = new String[]{};
        String[] fieldsList = new String[]{};
        String[] statusList = new String[]{};

        for (Integer i=0;i<urList.size();i++) {
            if (!urList[i].isSuccess()) {
                for (Database.Error err : urList[i].getErrors()) {
                    msgList.add('(' + sObjects[i].Id + '): ' + err.getMessage()+'; '+ '\n');
                    statusList.add('(' + sObjects[i].Id + '): ' + err.getStatusCode()+'; '+ '\n');
                    fieldsList.add('(' + sObjects[i].Id + '): ' + err.getFields()+'; '+ '\n');
                }
            }
        }

        log.Message__c = String.join(msgList,'');
        log.Status_Code__c = String.join(statusList,'');
        log.Affected_Fields__c = String.join(fieldsList,'');
        log.Type__c = 'Batch Upsert Errors';

        insert log;
        return log;
    }

    // process a Database DeleteResult error array and log to the custom Error Log object.  Sorted by ID
    public static Error_Log__c resultsByID(Database.DeleteResult[] drList, List<SObject> sObjects) {
        Error_Log__c log = new Error_Log__c();
        String[] msgList = new String[]{};
        String[] fieldsList = new String[]{};
        String[] statusList = new String[]{};

        for (Integer i=0;i<drList.size();i++) {
            if (!drList[i].isSuccess()) {
                for (Database.Error err : drList[i].getErrors()) {
                    msgList.add('(' + sObjects[i].Id + '): ' + err.getMessage()+'; '+ '\n');
                    statusList.add('(' + sObjects[i].Id + '): ' + err.getStatusCode()+'; '+ '\n');
                    fieldsList.add('(' + sObjects[i].Id + '): ' + err.getFields()+'; '+ '\n');
                }
            }
        }

        log.Message__c = String.join(msgList,'');
        log.Status_Code__c = String.join(statusList,'');
        log.Affected_Fields__c = String.join(fieldsList,'');
        log.Type__c = 'Batch Delete Errors';

        insert log;
        return log;
    }

    // process results returned by ErrorHelper class on Save & Update.  Sorted by error
    public static Error_Log__c[] resultsByError(Database.SaveResult[] srList, List<SObject> sObjects) {
        Map<String, List<String>> errorMap = ErrorHelper.getErrorMap(srList, sObjects);
        List<Error_Log__c> newLogs = new List<Error_Log__c>();
        for (String err : errorMap.keySet()) {
            Error_Log__c log = new Error_Log__c();
            log.Message__c = err.split(';')[1].split('=')[1];
            log.Status_Code__c = err.split(';')[2].split('=')[1];
            log.Affected_Fields__c = err.split(';')[0].split('=')[1];
            if (errorMap.get(err) != null) {
                log.Record_IDs__c = String.join(errorMap.get(err),';\n');
            }
            log.Type__c = 'Batch Insert/Update Error';
            newLogs.add(log);
        }
        insert newLogs;
        return newLogs;
    }

    // include "upsertKey" for upsert results - this will be a custom ID field to set the id on results as failed upserts have Id=null
    public static Error_Log__c[] resultsByError(Database.UpsertResult[] urList, List<SObject> sObjects, String upsertKey) {
        Map<String, List<String>> errorMap = ErrorHelper.appendErrorMap(urList, sObjects, upsertKey, new Map<String, List<String>>());
        List<Error_Log__c> newLogs = new List<Error_Log__c>();
        for (String err : errorMap.keySet()) {
            Error_Log__c log = new Error_Log__c();
            log.Message__c = err.split(';')[1].split('=')[1];
            log.Status_Code__c = err.split(';')[2].split('=')[1];
            log.Affected_Fields__c = err.split(';')[0].split('=')[1];
            log.Record_IDs__c = String.join(errorMap.get(err),';\n');
            log.Type__c = 'Batch Upsert Error';
            newLogs.add(log);
        }
        insert newLogs;
        return newLogs;
    }

    // process results returned by ErrorHelper class on Delete.  Sorted by error
    public static Error_Log__c[] resultsByError(Database.DeleteResult[] drList, List<SObject> sObjects) {
        Map<String, List<String>> errorMap = ErrorHelper.appendErrorMap(drList, sObjects, new Map<String, List<String>>());
        List<Error_Log__c> newLogs = new List<Error_Log__c>();
        for (String err : errorMap.keySet()) {
            Error_Log__c log = new Error_Log__c();
            log.Message__c = err.split(';')[1].split('=')[1];
            log.Status_Code__c = err.split(';')[2].split('=')[1];
            log.Affected_Fields__c = err.split(';')[0].split('=')[1];
            log.Record_IDs__c = String.join(errorMap.get(err),';\n');
            log.Type__c = 'Batch Delete Error';
            newLogs.add(log);
        }
        insert newLogs;
        return newLogs;
    }
}

/*
    Want to grab all errors from a Database.SaveResult/UpdateResult/DeleteResult array and concat
    so that they can live in one place and not write a new log for each error.  Check ErrorHelper.cls
    for ideas.
*/