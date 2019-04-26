@isTest
private class PaymentsControllerTest {

	@testSetup 
	static void setup() {
		TestDataFactory tdf = new TestDataFactory();
		tdf.regularInit(3, 3);
	}

	@isTest static void test_PaymentsController() {
		PaymentsController.SectionPage page = new PaymentsController.SectionPage();
		page.query = 'test';
		page.orderBy = 'Name ASC';
		page = PaymentsController.getPayments(JSON.serialize(page));
		System.assert(String.isNotBlank(page.query), 'Pass through search parameter');
		System.assert(String.isNotBlank(page.orderBy), 'Pass through order by parameter');

		page.query = null;
		page.orderBy = null;
		page = PaymentsController.getPayments(JSON.serialize(page));
		System.assert(page.sections.size() > 0, 'Pull and prepare Contacts');
		System.assert(page.sections[0].payments.size() > 0, 'Pull and prepare Payments');

		Project_Payment__c payment = page.sections[0].payments[0];
		PaymentsController.Section section = PaymentsController.save(payment);
		System.assert(section.payments.size() == 1, 'Save Payment and return result');

		section = PaymentsController.remove(payment.Id);
		Boolean isRecordRemoved = true;
		for (Project_Payment__c p : section.payments) {
			isRecordRemoved = payment.Id == p.Id ? false : isRecordRemoved;
		}
		System.assert(isRecordRemoved, 'Delete Payment and return result');

		List<Project__c> projects = PaymentsController.getProjects();
		System.assert(projects.size() == 3, 'Pull Projects');
	}

}