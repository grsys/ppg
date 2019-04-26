@isTest
public class Test_ManagePaymentsExtension {
	
    @isTest
    static void testController() {
        
        Contact c1 = new Contact(LastName = 'TestContact1');
        Contact c2 = new Contact(LastName = 'TestContact1');
        List<Contact> cList = new List<Contact> {c1, c2};
        insert cList;
        
        Project__c p1 = new Project__c();
        p1.Name = 'TestProject1';
        insert p1;
        
        ApexPages.currentPage().getParameters().put('id', p1.id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(p1);
        ManagePaymentsExtension testController = new ManagePaymentsExtension(stdController);
        
        system.assertEquals(0, testController.records.size());
        
        // add new Payment for TestContact1
        testController.newProjectPayment.Contact__c = c1.Id;
        testController.newProjectPayment.Payment_Amount__c = 100;
		testController.add();
        
        system.assertEquals(1, testController.records.size());
        system.assertEquals(1, testController.records.get(0).payments.size());
        system.assertEquals(c1.Id, testController.records.get(0).contact.Id);
        system.assertEquals(100, testController.records.get(0).contact.Total_Payments__c);
        system.assertEquals(100, testController.project.Total_Payments__c);
        system.assertNotEquals(NULL, testController.project.Last_Payment_Date__c);
        
        // clear new Payment Section
        testController.clear();
        system.assertEquals(NULL, testController.newProjectPayment.Contact__c);
        system.assertEquals(NULL, testController.newProjectPayment.Payment_Amount__c);
        
        // add new Payment for TestContact2
        testController.newProjectPayment.Contact__c = c2.Id;
        testController.newProjectPayment.Payment_Amount__c = 150;
		testController.add();
        
        system.assertEquals(2, testController.records.size());
        system.assertEquals(1, testController.records.get(1).payments.size());
        system.assertEquals(c2.Id, testController.records.get(1).contact.Id);
        system.assertEquals(150, testController.records.get(1).contact.Total_Payments__c);
        system.assertEquals(250, testController.project.Total_Payments__c);
        system.assertNotEquals(NULL, testController.project.Last_Payment_Date__c);
        
        // add new Payment for TestContact2
        testController.newProjectPayment.Contact__c = c2.Id;
        testController.newProjectPayment.Payment_Amount__c = 250;
        testController.add();
        
        system.assertEquals(2, testController.records.size());
        system.assertEquals(2, testController.records.get(1).payments.size());
        system.assertEquals(c2.Id, testController.records.get(1).contact.Id);
        system.assertEquals(400, testController.records.get(1).contact.Total_Payments__c);
        system.assertEquals(500, testController.project.Total_Payments__c);
        system.assertNotEquals(NULL, testController.project.Last_Payment_Date__c);
        
        // update Payments Section & save
        testController.records.get(0).payments.get(0).Payment_Amount__c = 10;
        testController.records.get(1).payments.get(0).Payment_Amount__c = 15;
        testController.records.get(1).payments.get(1).Payment_Amount__c = 25;
        testController.saveAllPayments();
        
        system.assertEquals(2, testController.records.size());
        system.assertEquals(40, testController.records.get(1).contact.Total_Payments__c);
        system.assertEquals(50, testController.project.Total_Payments__c);
        system.assertNotEquals(NULL, testController.project.Last_Payment_Date__c);
        
        String backPageUrl = testController.back().getUrl();
        system.assertEquals('/' + String.valueOf(testController.project.Id), backPageUrl);
    }
}