trigger ProjectPaymentTrigger on Project_Payment__c (before insert, before update, before delete, after insert, after update, after delete) {
	TriggerFactory.executeHandler(ProjectPaymentTriggerHandler.class);
}