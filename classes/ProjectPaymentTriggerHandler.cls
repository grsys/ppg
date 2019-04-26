public with sharing class ProjectPaymentTriggerHandler extends TriggerHandler {

	public ProjectPaymentTriggerHandler() {}

	public override void bulkBeforeInsert(List<SObject> soList) {
		List<Project_Payment__c> payments = (List<Project_Payment__c>)soList;
		ProjectPaymentTriggerService.handleChanges(payments);
	}

	public override void bulkBeforeUpdate(List<SObject> oldSoList, List<SObject> soList) {
		List<Project_Payment__c> payments = (List<Project_Payment__c>)soList;
		List<Project_Payment__c> oldPayments = (List<Project_Payment__c>)oldSoList;
		ProjectPaymentTriggerService.handleChanges(payments, oldPayments);
	}

	public override void bulkAfterDelete(List<SObject> soList) {
		List<Project_Payment__c> payments = (List<Project_Payment__c>)soList;
		ProjectPaymentTriggerService.handleChanges(payments, false);
	}

}