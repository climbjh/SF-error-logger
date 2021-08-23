@isTest
private class ErrorLogging_Test {

    static testMethod void testBasic() {
        Account a = new Account();
        try {
            insert a;
        } catch (Exception e) {
            Error_Log__c log = ErrorLogging.basicError(e, 'Test');
            System.assertEquals('System.DmlException', log.Type__c);
        }
    }

    static testMethod void testResultsByID() {
        List<Account> accts = new List<Account>{
            new Account(Name='Account1'),
            new Account(Name='SuccessfulAcct', First_Name__c='Tom', Last_Name__c='Brady'),
            new Account()
        };

        Database.SaveResult[] srList = Database.insert(accts, false);
        Error_Log__c log = ErrorLogging.resultsByID(srList);
        System.assertEquals('Batch Insert/Update Errors', log.Type__c);

        Database.UpsertResult[] urList = Database.upsert(accts, false);
        Error_Log__c log2 = ErrorLogging.resultsByID(urList, accts);
        System.assertEquals('Batch Upsert Errors', log2.Type__c);

        List<Account> accountList = new List<Account>{
            new Account(Name='Acct1', First_Name__c='NEW', Last_Name__c='Acct'),
            new Account(Name='Acct2', First_Name__c='NEW', Last_Name__c='Acct'),
            new Account(Name='Acct3', First_Name__c='NEW', Last_Name__c='Acct')
        };
        insert accountList;

        List<Account> deleteAccts = [SELECT Id FROM Account];

        delete deleteAccts;
        Database.DeleteResult[] drList = Database.delete(deleteAccts, false);
        Error_Log__c log3 = ErrorLogging.resultsByID(drList, deleteAccts);
        System.assertEquals('Batch Delete Errors', log3.Type__c);
    }

    static testMethod void testResultsByError() {
        List<Account> accts = new List<Account>{
            new Account(Name='Account1'),
            new Account(Name='SuccessfulAcct', First_Name__c='Tom', Last_Name__c='Brady'),
            new Account()
        };

        Database.SaveResult[] srList = Database.insert(accts, false);
        Error_Log__c[] logs = ErrorLogging.resultsByError(srList, accts);
        System.assertEquals('Batch Insert/Update Error', logs[0].Type__c);

        Database.UpsertResult[] urList = Database.upsert(accts, false);
        Error_Log__c[] logs2 = ErrorLogging.resultsByError(urList, accts, 'Id');
        System.debug(logs2);
        System.assertEquals('Batch Upsert Error', logs2[0].Type__c);

        List<Account> acctList = new List<Account>{
            new Account(Name='Acct1', First_Name__c='NEW', Last_Name__c='Acct'),
            new Account(Name='Acct2', First_Name__c='NEW', Last_Name__c='Acct'),
            new Account(Name='Acct3', First_Name__c='NEW', Last_Name__c='Acct')
        };
        insert acctList;

        List<Account> newAccts = [SELECT Id FROM Account];

        delete newAccts;
        Database.DeleteResult[] drList = Database.delete(newAccts, false);
        Error_Log__c[] logs3 = ErrorLogging.resultsByError(drList, newAccts);
        System.assertEquals('Batch Delete Error', logs3[0].Type__c);
    }
}
