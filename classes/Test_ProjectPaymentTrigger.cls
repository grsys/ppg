@isTest
public class Test_ProjectPaymentTrigger {

    @isTest
    static void testBulkInsertScenario() {

        TestDataFactory tdf = new TestDataFactory();
        tdf.regularInit(10, 5);

        Test.startTest();

        Contact randomContact = tdf.contacts.get(getRandomIndex(10-1));
        Project__c randomProject = tdf.projects.get(getRandomIndex(5-1));

        randomContact = getContact(randomContact.Id);
        randomProject = getProject(randomProject.Id);

        AggregateResult[] lastPaymentDateForProject = getLastPaymentDateForProject(randomProject.Id);
        AggregateResult[] lastPaymentDateForContact = getLastPaymentDateForContact(randomContact.Id);

        System.assertEquals(1, lastPaymentDateForProject.size());
        System.assertEquals(1, lastPaymentDateForContact.size());

        Date lastPaymentDateContact = (Date)lastPaymentDateForContact.get(0).get('lastPaymentDate');
        Date lastPaymentDateProject = (Date)lastPaymentDateForProject.get(0).get('lastPaymentDate');

        System.assertNotEquals(NULL, randomContact);
        // 1 projects * (100 + 100 + 100 + 100 + 100) = 500;
        System.assertEquals(500, randomContact.Total_Payments__c);
        System.assertEquals(lastPaymentDateContact, randomContact.Last_Payment_Date__c);

        System.assertNotEquals(NULL, randomProject);
        // 10 contacts * (100) = 1000;
        System.assertEquals(1000, randomProject.Total_Payments__c);
        System.assertEquals(lastPaymentDateProject, randomProject.Last_Payment_Date__c);

        Test.stopTest();

    }

    @isTest
    static void testBulkUpdateScenario() {

        TestDataFactory tdf = new TestDataFactory();
        tdf.regularInit(10, 5);

        Test.startTest();

        // increase each payment by 2
        List<Project_Payment__c> paymentsToUpdate = [SELECT Id, Payment_Amount__c, Payment_Date__c FROM Project_Payment__c LIMIT 200];
        for(Project_Payment__c pp : paymentsToUpdate) {
            pp.Payment_Amount__c = pp.Payment_Amount__c * 2;
        }

        update paymentsToUpdate;

        Contact randomContact = tdf.contacts.get(getRandomIndex(10-1));
        Project__c randomProject = tdf.projects.get(getRandomIndex(5-1));

        randomContact = getContact(randomContact.Id);
        randomProject = getProject(randomProject.Id);

        AggregateResult[] lastPaymentDateForProject = getLastPaymentDateForProject(randomProject.Id);
        AggregateResult[] lastPaymentDateForContact = getLastPaymentDateForContact(randomContact.Id);

        System.assertEquals(1, lastPaymentDateForProject.size());
        System.assertEquals(1, lastPaymentDateForContact.size());

        Date lastPaymentDateContact = (Date)lastPaymentDateForContact.get(0).get('lastPaymentDate');
        Date lastPaymentDateProject = (Date)lastPaymentDateForProject.get(0).get('lastPaymentDate');

        System.assertNotEquals(NULL, randomContact);
        // 1 projects * (2*100 + 2*100 + 2*100 + 2*100 + 2*100) = 1000;
        System.assertEquals(1000, randomContact.Total_Payments__c);
        System.assertEquals(lastPaymentDateContact, randomContact.Last_Payment_Date__c);

        System.assertNotEquals(NULL, randomProject);
        // 10 contacts * (2*100) = 2000;
        System.assertEquals(2000, randomProject.Total_Payments__c);
        System.assertEquals(lastPaymentDateProject, randomProject.Last_Payment_Date__c);

        Test.stopTest();

    }

    @isTest
    static void testBulkDeleteScenario() {

        TestDataFactory tdf = new TestDataFactory();
        tdf.regularInit(10, 5, 2);

        Test.startTest();

        List<Project_Payment__c> paymentsToDelete = new List<Project_Payment__c>();
        // delete 1 payment from each contact
        for(Integer i=0; i < 10; i++) {
            Project_Payment__c pp = tdf.payments[i*5+1];
            paymentsToDelete.add(pp);
        }
        delete paymentsToDelete;

        Contact randomContact = tdf.contacts.get(getRandomIndex(10-1));
        Project__c randomProject = tdf.projects.get(getRandomIndex(5-1));

        randomContact = getContact(randomContact.Id);
        randomProject = getProject(randomProject.Id);

        AggregateResult[] lastPaymentDateForProject = getLastPaymentDateForProject(randomProject.Id);
        AggregateResult[] lastPaymentDateForContact = getLastPaymentDateForContact(randomContact.Id);

        System.assertEquals(1, lastPaymentDateForProject.size());
        System.assertEquals(1, lastPaymentDateForContact.size());

        Date lastPaymentDateContact = (Date)lastPaymentDateForContact.get(0).get('lastPaymentDate');
        Date lastPaymentDateProject = (Date)lastPaymentDateForProject.get(0).get('lastPaymentDate');

        System.assertNotEquals(NULL, randomContact);
        // 5 projects  (4 * 2*100) = 800;
        System.assertEquals(800, randomContact.Total_Payments__c);
        System.assertEquals(lastPaymentDateContact, randomContact.Last_Payment_Date__c);

        Test.stopTest();

    }

    private static Project__c getProject(Id projectId) {
        Project__c project = [
            SELECT Id, Total_Payments__c, Last_Payment_Date__c
            FROM Project__c
            WHERE Id = :projectId
            LIMIT 1
        ];
        return project;
    }

    private static Contact getContact(Id contactId) {
        Contact contact = [
            SELECT Id, Total_Payments__c, Last_Payment_Date__c
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
        return contact;
    }

    private static AggregateResult[] getLastPaymentDateForProject(Id projectId) {
        AggregateResult[] lastPaymentDateForProject = [
            SELECT Project__c,  MAX(Payment_Date__c)lastPaymentDate
            FROM Project_Payment__c
            WHERE Project__c = :projectId
            GROUP BY Project__c
        ];
        return lastPaymentDateForProject;
    }

    private static AggregateResult[] getLastPaymentDateForContact(Id contactId) {
        AggregateResult[] lastPaymentDateForContact = [
            SELECT Contact__c,  MAX(Payment_Date__c)lastPaymentDate
            FROM Project_Payment__c
            WHERE Contact__c = :contactId
            GROUP BY Contact__c
        ];
        return lastPaymentDateForContact;
    }

    private static Integer getRandomIndex(Integer max) {
        Double randomNumber = Math.random();
        Integer maxIndex = max;
        Integer randomIndex = (randomNumber *(maxIndex)).intValue();
        return randomIndex;
    }


    static Integer getRandomDay() {
        Double randomNumber = Math.random();
        Integer maxIndex = 14;
        Integer randomIndex = (randomNumber *(maxIndex)).intValue();
        return randomIndex -7;
    }

}