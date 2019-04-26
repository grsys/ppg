public with sharing class ManagePaymentsExtension {

    public Project__c project {get; set;}
    public Project_Payment__c newProjectPayment { get; set; }
    public List<ContactWrapper> records {get; set;}


    public ManagePaymentsExtension(ApexPages.StandardController stdController) {
        this.project = (Project__c)stdController.getRecord();
        this.newProjectPayment = new Project_Payment__c();
        this.newProjectPayment.Project__c = this.project.Id;
        init();
    }

    private void init() {
        this.project = [
            SELECT Id,Total_Payments__c, Last_Payment_Date__c
            FROM Project__c
            WHERE Id = :this.project.Id
            LIMIT 1
        ];

        this.records = new List<ContactWrapper>();
        Map<Id, ContactWrapper> wrappedMap = new Map<Id, ContactWrapper>();

        List<Project__c> tmpRecords = [
            SELECT
                Id,
                Last_Payment_Date__c,
                Total_Payments__c,
                (SELECT
                    Id,
                    Name,
                    Contact__r.Name,
                    Contact__r.Id,
                 	Contact__r.Total_Payments__c,
                 	Contact__r.Last_Payment_Date__c,
                    Payment_Amount__c,
                    Payment_Date__c,
                 	Project__c
                FROM Project_Payment__r)
            FROM Project__c
            WHERE Id = :this.project.Id
            LIMIT 1000
        ];

        for (Project__c rec : tmpRecords) {
            List<Project_Payment__c> payments = (rec.getSObjects('Project_Payment__r') != NULL) ?
                (List<Project_Payment__c>)rec.getSObjects('Project_Payment__r') :
            	new List<Project_Payment__c>();

            for (Project_Payment__c payment : payments) {
                Contact contact = (Contact)payment.getSobject('Contact__r');
                ContactWrapper cw = wrappedMap.get(contact.Id);

                if (cw == NULL) {
                    cw = new ContactWrapper(contact, new List<Project_Payment__c> {payment});
                }
                else {
                    cw.payments.add(payment);
                }
                cw.updateTotalPayments(payment.Payment_Amount__c);
                wrappedMap.put(contact.Id, cw);
            }
        }

        AggregateResult[] lastPaymentDateForContact = [
			SELECT Contact__c,  MAX(Payment_Date__c)lastPaymentDate
		    FROM Project_Payment__c
		    WHERE Project__c =:this.project.Id AND Contact__c IN :wrappedMap.keySet()
		    GROUP BY Contact__c
		];

        for (AggregateResult ar : lastPaymentDateForContact) {
		   Id contactId = (Id)ar.get('Contact__c');
		   Date lastPaymentDate = (Date)ar.get('lastPaymentDate');
		   ContactWrapper cw = wrappedMap.get(contactId);
           cw.updatePaymentDate(lastPaymentDate);
           wrappedMap.put(contactId, cw);
		}

        if (!wrappedMap.isEmpty()) {
            this.records = wrappedMap.values();
            System.debug(JSON.serialize(this.records));
        }

    }

    public void saveAllPayments() {
        List<Project_Payment__c> paymentsToUpdate = new List<Project_Payment__c>();
        for (ContactWrapper cw : this.records) {
            paymentsToUpdate.addAll(cw.payments);
        }

        Boolean isError = true;
        if (!paymentsToUpdate.isEmpty()) {
            try {
                update paymentsToUpdate;
                isError = false;
            }
            catch (DMLException e) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Error:' + e.getMessage()));
            }
        }

        if (!isError) {
           init();
        }
    }

    public void add() {
        Project_Payment__c newPayment = new Project_Payment__c();
        newPayment.Payment_Date__c = (this.newProjectPayment.Payment_Date__c == NULL) ? Date.today() : this.newProjectPayment.Payment_Date__c;
        newPayment.Payment_Amount__c = this.newProjectPayment.Payment_Amount__c;
        newPayment.Contact__c = this.newProjectPayment.Contact__c;
        newPayment.Project__c = this.project.Id;

        Boolean isError = true;
        try {
            insert newPayment;
            isError = false;
         }
         catch (DMLException e) {
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Error:' + e.getMessage()));
         }

        if (!isError) {
           init();
        }
    }

    public void clear() {
        this.newProjectPayment.Contact__c = NULL;
        this.newProjectPayment.Payment_Amount__c = NULL;
        this.newProjectPayment.Payment_Date__c = NULL;
    }

    public PageReference back() {
        PageReference pr = new PageReference('/' + String.valueOf(this.project.Id));
        pr.setRedirect(true);
        return pr;
    }

    public class ContactWrapper {

        public Contact contact {get; set;}
        public List<Project_Payment__c> payments {get; set;}

        public ContactWrapper(Contact contact, List<Project_Payment__c> payments){
            this.contact = contact;
            this.contact.Total_Payments__c = 0;
            this.payments = payments;
        }

        public void updateTotalPayments(Decimal value) {
            if (value != NULL) {
           		this.contact.Total_Payments__c += value;
            }
        }

        public void updatePaymentDate(Date value) {
            if (value != NULL) {
           		this.contact.Last_Payment_Date__c = value;
            }
        }

    }
}