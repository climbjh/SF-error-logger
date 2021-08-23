/*
Developer: JLC <jlc@callawaycloudconsulting.com> July 2018
Description: Test methods for ErrorHelper
*/
@isTest

private class ErrorHelper_Test {

    static Map<String, List<String>> errorMap = new Map<String, List<String>>();

    static testMethod void testDBoperations() {

        Lead l1 = TestUtil.createLead();
        Lead l2 = TestUtil.createLead();
        Lead l3 = TestUtil.createLead();
        l1.Email = 'l1@test.com';
        l2.Email = 'l2@test.com';
        l3.Email = 'l3=test.com';
        List<Lead> leads = new List<Lead>{l1,l2,l3}; 

        List<Database.SaveResult> saveResults = Database.update(leads, false);
        ErrorHelper.appendErrorMap(saveResults, leads, errorMap);        
        System.assertEquals(1, errorMap.size());  
        
        Map<String, List<Database.Error>> errorsByIdMap = ErrorHelper.getErrorsById(saveResults, leads);
        System.assertNotEquals(null, errorsByIdMap.get(l3.Id));  
        
        ErrorHelper.sendEmailErrorSummary(new List<String>{'test@test.com'}, 'Test Email', errorsByIdMap);        
        ErrorHelper.sendEmailErrorSummary(new List<String>{'test@test.com'}, 'Test Email', errorMap);        
        
        String errors;
        String errorsById;        
        for (Database.SaveResult sr : saveResults) {
            if (!sr.isSuccess()) {
                errors = ErrorHelper.getErrorSummary(sr.getErrors()); 
                Map<String, List<Database.Error>> errorsMap = new Map<String, List<Database.Error>>();
                errorsMap.put(l3.Id, sr.getErrors()); 
                errorsById = ErrorHelper.getErrorSummary(errorsMap);    
            }
        }
        System.assert(errors.contains('INVALID_EMAIL_ADDRESS'));                  
        System.assert(errorsById.contains(l3.Id));   
        
        errorMap = ErrorHelper.getErrorMap(saveResults, leads);
        System.assertEquals(1, errorMap.size()); 
        
        ErrorHelper.getErrorSummary(errorMap);              
        System.assert(errorsById.contains(l3.Id));   

        errorMap.clear();
        List<Database.UpsertResult> upsertResults = Database.upsert(leads, false);
        ErrorHelper.appendErrorMap(upsertResults, leads, 'Id',errorMap);        
        System.assertEquals(1, errorMap.size());  

        errorMap.clear();
        List<Database.DeleteResult> deleteResults = Database.delete(leads, false);
        ErrorHelper.appendErrorMap(deleteResults, leads, errorMap);        
        System.assertEquals(0, errorMap.size());  
             
    }
    
    static testMethod void testEmailOperations() {
        
        Lead l1 = TestUtil.createLead();
        Lead l2 = TestUtil.createLead();
        Lead l3 = TestUtil.createLead();
        l1.Email = 'l1@test.com';
        l2.Email = 'l2@test.com';
        l3.Email = 'l3=test.com';
        List<Lead> leads = new List<Lead>{l1,l2,l3}; 
        Database.update(leads, false);
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Lead l : leads) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(l.Id);
            mail.setSubject('Test Subject');
            mail.setPlainTextBody('Test Body');
            emails.add(mail);
        }
        List<Messaging.SendEmailResult> emailResults = Messaging.sendEmail(emails, false);
        errorMap.clear();
        ErrorHelper.appendErrorMap(emailResults, errorMap);
        System.assertEquals(1, errorMap.size());
        System.assertEquals(string.valueOf(l3.Id), errorMap.values()[0][0]);
        
    }
}