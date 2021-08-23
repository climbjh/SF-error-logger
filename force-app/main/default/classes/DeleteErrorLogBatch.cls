global class DeleteErrorLogBatch implements Schedulable, Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM Error_Log__c WHERE createdDate = LAST_N_DAYS:30]);
    }

    public void execute(Database.BatchableContext bc, List<Error_Log__c> scope) {
        if (!scope.isEmpty()) {
            delete scope;
        }
    }

    public void finish(Database.BatchableContext bc) {

    }

    global void execute(SchedulableContext sc) {

        DeleteErrorLogBatch batch = new DeleteErrorLogBatch();
        Database.executeBatch(batch, 100);

    }

}