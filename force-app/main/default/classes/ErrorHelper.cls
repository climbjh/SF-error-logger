/*
Developer: Ralph Callaway <ralph@callawaycloudconsulting.com>
Description:
    Helper methods for processing errors
*/
public class ErrorHelper {

    // Converts an error into a string
    public static String toString(Database.Error error) {
        return String.valueOf(error).replace('\n',' ');
    }

    // Returns a summary of a list of errors
    public static String getErrorSummary(List<Database.Error> errors) {
        List<String> summaries = new List<String>();
        for(Database.Error error : errors) {
            summaries.add(toString(error));
        }
        return String.join(summaries, ', ');
    }

    // Returns a summary of errors by id
    public static String getErrorSummary(Map<String, List<Database.Error>> errorsById) {
        List<String> errors = new List<String>();
        for(String objId : errorsById.keySet()) {
            errors.add(objId + ': ' + getErrorSummary(errorsById.get(objId)));
        }
        return String.join(errors, '\n');
    }

    // Get a summary of errors with ids
    public static String getErrorSummary(Map<String, List<String>> errorsWithIds) {
        List<String> summaries = new List<String>();
        for(String error : errorsWithIds.keySet()) {
            List<String> ids = errorsWithIds.get(error);
            String summary = ids.size() + ' records failed with error: ' + error + '.' +
                    ' Failing Ids: ' + String.join(ids, ', ');
            summaries.add(summary);
        }
        return String.join(summaries, '\n');
    }

    // Returns a map with errors for keys, and the set of records that failed for that error
    // as ids
    public static Map<String, List<String>> getErrorMap(List<Database.SaveResult> saveResults, List<SObject> sObjects) {
        return appendErrorMap(saveResults, sObjects, new Map<String, List<String>>());
    }

    public static Map<String, List<String>> appendErrorMap(List<Database.SaveResult> saveResults, List<SObject> sObjects,
            Map<String, List<String>> errorMap) {
        return appendErrorMap(resultList(saveResults, sObjects), errorMap);
    }

    public static Map<String, List<String>> appendErrorMap(List<Database.DeleteResult> deleteResults, List<SObject> sObjects,
            Map<String, List<String>> errorMap) {
        return appendErrorMap(resultList(deleteResults, sObjects), errorMap);
    }

    public static Map<String, List<String>> appendErrorMap(List<Database.UpsertResult> upsertResults, List<SObject> sObjects,
            String upsertKey, Map<String, List<String>> errorMap) {
        return appendErrorMap(resultList(upsertResults, sObjects, upsertKey), errorMap);
    }

    public static Map<String, List<String>> appendErrorMap(List<Messaging.SendEmailResult> sendEmailResults, Map<String, List<String>> errorMap) {
        return appendErrorMap(resultList(sendEmailResults), errorMap);
    }

    private static Map<String, List<String>> appendErrorMap(List<Result> results, Map<String, List<String>> errorMap) {
        for(Result result : results) {
            if(!result.isSuccess) {
                if (result.isDataBase) {
                    for(Database.Error error : result.errors) {
                        String errMsg = toString(error);
                        if(!errorMap.containsKey(errMsg)) {
                            errorMap.put(errMsg, new List<String>());
                        }
                        errorMap.get(errMsg).add(result.Id);
                    }
                } else if (result.isEmail) {
                    for(Messaging.SendEmailError error : result.emailErrors) {
                        String errMsg = error.getMessage();
                        if(!errorMap.containsKey(errMsg)) {
                            errorMap.put(errMsg, new List<String>());
                        }
                        errorMap.get(errMsg).add(result.Id);
                    }
                }
            }
        }
        // System.debug(errorMap);
        return errorMap;
    }

    // Below method is used in the event that we need a "What Id" included in our results list after sending an email
    // ONLY should be used for email results
    public static Map<String, List<String>> appendErrorMapWithWhatId(List<Messaging.SingleEmailMessage> originalMessageList,
    List<Messaging.SendEmailResult> sendEmailResults, Map<String, List<String>> errorMap){
        List<Result> results = resultListWithWhatId(sendEmailResults, originalMessageList);
        for(Result result : results){
            if(!result.isSuccess) {
                for(Messaging.SendEmailError error : result.emailErrors) {
                    String errMsg = error.getMessage();
                    if(!errorMap.containsKey(errMsg)) {
                        errorMap.put(errMsg, new List<String>());
                    }
                    errorMap.get(errMsg).add(result.Id);
                }
            }
        }
        return errorMap;
    }

    // Returns a map of database errors for failing saves by record id
    public static Map<String, List<Database.Error>> getErrorsById(List<Database.SaveResult> saveResults, List<SObject> sObjects) {
        Map<String, List<Database.Error>> errorMap = new Map<String, List<Database.Error>>();
        for(Integer i = 0; i < saveResults.size(); i++) {
            Database.SaveResult saveResult = saveResults[i];
            SObject sObj = sObjects[i];
            if(!saveResult.isSuccess()) {
                errorMap.put(sObj.Id, saveResult.getErrors());
            }
        }
        System.debug(errorMap);
        return errorMap;
    }

    // Sends an email with a summary of errors
    public static void sendEmailErrorSummary(List<String> recipients, String subject, Map<String, List<Database.Error>> errorsById) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setPlainTextBody(getErrorSummary(errorsById));
        email.setSubject(subject);
        email.setToAddresses(recipients);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }

    // Sends an email with a summary of errors
    public static void sendEmailErrorSummary(List<String> recipients, String subject, Map<String,
            List<String>> errorsWithIds) {
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { generateEmailErrorSummary(recipients, subject, errorsWithIds) });
    }

    // Sends an email with a summary of errors with a text explanation of the failure
    public static void sendEmailErrorSummary(List<String> recipients, String subject,
    Map<String,List<String>> errorsWithIds, String userFriendlyMsg) {
        Messaging.SingleEmailMessage msg = generateEmailErrorSummary(recipients, subject, errorsWithIds);
        String body = userFriendlyMsg + '\n' + msg.getPlainTextBody();
        msg.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {msg});
    }

    // Generates an email body but doesn't send
    public static Messaging.SingleEmailMessage generateEmailErrorSummary(List<String> recipients, String subject, Map<String,
            List<String>> errorsWithIds) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setPlainTextBody(getErrorSummary(errorsWithIds));
        email.setSubject(subject);
        email.setToAddresses(recipients);
        return email;
    }

    private static List<Result> resultList(List<Database.DeleteResult> deleteResults, List<SObject> sObjects) {
        List<Result> output = new List<Result>();
        for(Integer i = 0; i < sObjects.size(); i++) {
            Database.DeleteResult deleteResult = deleteResults[i];
            SObject obj = sObjects[i];
            output.add(new Result(deleteResult, obj));
        }
        return output;
    }

    private static List<Result> resultList(List<Database.UpsertResult> upsertResults, List<SObject> sObjects, String upsertKey) {
        List<Result> output = new List<Result>();
        for(Integer i = 0; i < sObjects.size(); i++) {
            Database.UpsertResult upsertResult = upsertResults[i];
            SObject obj = sObjects[i];
            output.add(new Result(upsertResult, obj, upsertKey));
        }
        return output;
    }

    private static List<Result> resultList(List<Database.SaveResult> saveResults, List<SObject> sObjects) {
        List<Result> output = new List<Result>();
        for(Integer i = 0; i < sObjects.size(); i++) {
            Database.SaveResult saveResult = saveResults[i];
            SObject obj = sObjects[i];
            output.add(new Result(saveResult, obj));
        }
        return output;
    }

    private static List<Result> resultList(List<Messaging.SendEmailResult> SendEmailResults) {
        List<Result> output = new List<Result>();
        for(Messaging.SendEmailResult sendEmailResult : SendEmailResults) {
            for (Messaging.SendEmailError sendEmailError : sendEmailResult.getErrors()) {
                output.add(new Result(sendEmailResult, sendEmailError));
            }
        }
        return output;
    }

    private static List<Result> resultListWithWhatId(List<Messaging.SendEmailResult> SendEmailResults,
    List<Messaging.SingleEmailMessage> originalMessageList) {
        List<Result> output = new List<Result>();
        for(Integer i = 0; i < SendEmailResults.size(); i++){
            for (Messaging.SendEmailError sendEmailError : SendEmailResults[i].getErrors()) {
                Result r = new Result(SendEmailResults[i], sendEmailError);
                r.Id = originalMessageList[i].getWhatId();
                output.add(r);
            }
        }
        return output;
    }

    // Generalized result class
    private class Result {
        List<Database.Error> errors;
        List<Messaging.SendEmailError> emailErrors;
        Boolean isSuccess;
        Boolean isEmail;
        Boolean isDatabase;
        String id; // string for upserts external ids
        //String whatId; // used to store the "WhatId" if an email was sent

        private Result(Database.DeleteResult res, SObject obj) {
            this.errors = res.getErrors();
            this.isSuccess = res.isSuccess();
            this.isEmail = false;
            this.isDatabase = true;
            this.id = obj.Id;
        }

        private Result(Database.UpsertResult res, SObject obj, String upsertKey) {
            this.errors = res.getErrors();
            this.isSuccess = res.isSuccess();
            this.isEmail = false;
            this.isDatabase = true;
            if(obj.Id != null) {
                this.id = obj.Id;
            } else if(String.isNotBlank(upsertKey)) {
                this.id = (String) obj.get(upsertKey);
            }
        }

        private Result(Database.SaveResult res, SObject obj) {
            this.errors = res.getErrors();
            this.isSuccess = res.isSuccess();
            this.isEmail = false;
            this.isDatabase = true;
            this.id = obj.Id;
        }

        private Result(Messaging.SendEmailResult res, Messaging.SendEmailError err) {
            this.emailErrors = res.getErrors();
            this.isSuccess = res.isSuccess();
            this.isEmail = true;
            this.isDatabase = false;
            if (res.isSuccess()) {
                this.id = null;
            } else {
                this.id = err.getTargetObjectId();
            }
        }
    }
}