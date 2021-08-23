@isTest
private class DeleteErrorLogBatch_Test {

    @testSetup
    static void setup() {
        List<Error_Log__c> logs = new List<Error_Log__c>();

        // insert 10 Error Logs
        for (Integer i=0;i<10;i++) {
            logs.add(new Error_Log__c(Message__c='Log '+i));
        }

        insert logs;
    }

    @isTest static void batchDeleteTest() {

        String cron = '0 0 14 * * ?';

        Test.startTest();
        DeleteErrorLogBatch logBatch = new DeleteErrorLogBatch();
        Id batchId = Database.executeBatch(logBatch);
        String jobID = System.schedule('ScheduledApexTest', cron, new DeleteErrorLogBatch());
        Test.stopTest();

        // after the testing stops, assert records were updated properly
        System.assertEquals(0, [SELECT count() FROM Error_Log__c]);
    }
}