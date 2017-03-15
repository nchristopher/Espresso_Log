/*
* This class is generic class for creating theLogs
*/
global with sharing class LogBundle {
        private List<Log__c> theLogs = new List<Log__c>();
        private static final Map<String, List<String>> theLogLevelsMap = new Map<String, List<String>> { 'ERROR' => new List<String> { 'ERROR' } , 'WARN' => new List<String> { 'ERROR' , 'WARN' } , 'INFO' => new List<String> { 'ERROR' , 'WARN' , 'INFO' } , 'INFO' => new List<String> { 'ERROR' , 'WARN' , 'INFO' } , 'DEBUG' => new List<String> { 'ERROR' , 'WARN' , 'INFO' , 'DEBUG' } , 'FINE' => new List<String> { 'ERROR' , 'WARN' , 'INFO' , 'DEBUG' , 'FINE' } , 'FINER' => new List<String> { 'ERROR' , 'WARN' , 'INFO' , 'DEBUG' , 'FINE' , 'FINER' } , 'FINEST' => new List<String> { 'ERROR' , 'WARN' , 'INFO' , 'DEBUG' , 'FINE' , 'FINER' , 'FINEST' } };
         
        global LogBundle() {
        }
        
        global void addLogMessage(String theTitle, String theProcessType, String theCode, Id theRelatedId, System.LoggingLevel theLevel, String theMessage){
            addLog(theTitle, theProcessType, theCode, theRelatedId, theLevel, theMessage);
        }
        
        global void addException(String theTitle, String theProcessType, String theCode, Id theRelatedId, System.LoggingLevel theLevel, Exception ex) {
            addLog(theTitle, theProcessType, theCode, theRelatedId, theLevel, ex.getMessage() + ' Line Number - ' + ex.getLineNumber() +': ' + ex.getStackTraceString());
        }
        
        global Boolean hasMessages() {
            for (Log__c thisLog : theLogs) {
                if (thisLog.Status__c.toUpperCase() == 'ERROR') {
                    return true;
                }
            }
            
            return false;
        }
        
        private void addLog(String theTitle, String theProcessType, String theCode, Id theRelatedId, System.LoggingLevel theLevel, String theMessage) {
            Log_Setting__c theLogSettings = Log_Setting__c.getInstance();
            
            if (theLogSettings != null) {
	            List<String> theValidLogLevels = LogBundle.theLogLevelsMap.get(theLogSettings.Logging_Level__c);
	            
	            if (theValidLogLevels != null) {
	                for (String thisValidLogLevel : theValidLogLevels) {
	                    if (theLevel.name() == thisValidLogLevel) {
	                        Log__c thisLog = new Log__c(Name=theTitle,Start_Time__c=system.now(),End_Time__c=system.now(),Type__c=theProcessType,Status__c=theLevel.name(),Error_Code__c=theCode,Related_Id__c=theRelatedId,Message__c=theMessage);
	                        
	                        theLogs.add(thisLog);
	                    }
	                }
	            }
            }
        }
        
        global void endLogging() {
            Log_Setting__c theLogSettings = Log_Setting__c.getInstance();
            
            if (theLogSettings != null && theLogSettings.Send_Error_Email__c) {
            	List<Messaging.SingleEmailMessage> theErrorEmails = new List<Messaging.SingleEmailMessage>();
            	
	            for (Log__c thisLog : theLogs) {
	            	Messaging.SingleEmailMessage theErrorEmail = new Messaging.SingleEmailMessage();
                    String[] toAddresses = new String[] { theLogSettings.Error_Email_Address__c };
                    theErrorEmail.setToAddresses(toAddresses);
                    theErrorEmail.setReplyTo(theLogSettings.Error_Email_Reply_To__c);
                    theErrorEmail.setSenderDisplayName(theLogSettings.Error_Email_Sender_Name__c);
                    theErrorEmail.setSubject('Espresso Billing Error');
                    theErrorEmail.setBccSender(false);
                    theErrorEmail.setUseSignature(false);
                    theErrorEmail.setPlainTextBody(thisLog.Name + ' - ' + thisLog.Message__c);
                    
                    theErrorEmails.add(theErrorEmail);
	            }
	            
	            Messaging.sendEmail(theErrorEmails);
            }
            
            insert theLogs;
        }
        
        global class GeneralException extends Exception { }
        
        /********************* Test Methods*******************/
        TestMethod static void test_All() {
        	if (Log_Setting__c.getInstance() == null) {
        		Log_Setting__c theLogSettings = new Log_Setting__c(Send_Error_Email__c=true,Error_Email_Address__c='test@test.test',Error_Email_Reply_To__c='test@test.test',Error_Email_Sender_Name__c='test');
        		
        		insert theLogSettings;
        	}
        	
            Test.startTest();
            LogBundle testLogBundle = new LogBundle();
            testLogBundle.hasMessages();
            
            try {
            	throw new GeneralException('THIS IS A TEST EXCEPTION');
            } catch(Exception ex) {
                testLogBundle.addException('Test', 'Test', 'Test', null, System.Logginglevel.ERROR, ex);    
            }
            
            testLogBundle.addLogMessage('Test', 'Test', 'Test', null, System.Logginglevel.ERROR, 'TEST MESSAGE');
            testLogBundle.hasMessages();
            testLogBundle.endLogging();
            Test.stopTest();
        }
        
}
