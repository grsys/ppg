public with sharing class PaymentsController {

	@AuraEnabled
	public static SectionPage getPayments(String page) {
		SectionPage parsedPage = (SectionPage)JSON.deserialize(page, PaymentsController.SectionPage.class);
		parsedPage.init();
		return parsedPage;
	}

	@AuraEnabled
	public static List<Project__c> getProjects() {
		return [SELECT Id, Name FROM Project__c];
	}

	@AuraEnabled
	public static Section save(Project_Payment__c payment) {
		try {
			upsert payment;
		}
		catch (Exception e) {
			throw new AuraHandledException((e instanceof DmlException) ? e.getDmlMessage(0) : e.getMessage());
		}
		Id contactId = payment.Contact__c;
		SectionPage dummyPage = new SectionPage();
		String contactQuery = 'SELECT ' + dummyPage.combineFields(payment.Id) + ' FROM Contact WHERE Id = :contactId';
		Contact c = Database.query(contactQuery);
		return new Section(c);
	}

	@AuraEnabled
	public static Section remove(Id paymentId) {
		Id contactId;
		try {
			Project_Payment__c projectPayment = [SELECT Id, Contact__c FROM Project_Payment__c WHERE Id = :paymentId];
			contactId = projectPayment.Contact__c;
			delete projectPayment;
		}
		catch (Exception e) {
			throw new AuraHandledException((e instanceof DmlException) ? e.getDmlMessage(0) : e.getMessage());
		}
		SectionPage dummyPage = new SectionPage();
		String contactQuery = 'SELECT ' + dummyPage.combineFields(null) + ' FROM Contact WHERE Id = :contactId';
		Contact c = Database.query(contactQuery);
		return new Section(c);
	}

	public class SectionPage {

		@AuraEnabled
		public List<Section> sections { get; set; }

		@AuraEnabled
		public String query { get; set; }

		@AuraEnabled
		public String orderBy { get; set; }

		@AuraEnabled
		public Pager pagination { get; set; }

		public SectionPage() {
			
		}

		public void init() {
			Set<Id> contactWithPaymentIds = new Set<Id>();
			for (Project_Payment__c p : [SELECT Contact__c FROM Project_Payment__c]) {
				contactWithPaymentIds.add(p.Contact__c);
			}
			List<String> contactWhere = new List<String> {
				'Id IN :contactWithPaymentIds'
			};
			if (String.isNotBlank(this.query)) {
				contactWhere.add('Name LIKE \'%' + String.escapeSingleQuotes(this.query) + '%\'');
			}
			String contactQuery = 'SELECT ' + this.combineFields(null) + ' FROM Contact ';
			contactQuery += 'WHERE ' + String.join(contactWhere, ' AND ');
			if (String.isNotBlank(this.orderBy)) {
				contactQuery += ' ORDER BY ' + this.orderBy;
			}
			List<Contact> allContacts = Database.query(contactQuery);
			Integer pageNumber = this.pagination == null ? 1 : this.pagination.page;
			this.pagination = new Pager(pageNumber, allContacts.size());

			this.sections = new List<Section>();
			for (Integer j = this.pagination.index_start; j < this.pagination.index_end; j++) {
				this.sections.add(new Section(allContacts[j]));
			}
		}

		public String combineFields(Id paymentId) {
			String relatedPayments = '(Select ' + String.join(PAYMENT_FIELDS, ', ') + ' From Project_Payment__r ';
			relatedPayments += paymentId == null ? 'Order By Id Desc)' : ('Where Id = \'' + paymentId + '\')');
			List<String> contactFields = new List<String>();
            contactFields.addAll(CONTACT_FIELDS);
            contactFields.add(relatedPayments);

            return String.join(contactFields, ', ');
		}
	}

	public static final Integer PAGE_SIZE = 3;
    public static final List<String> PAYMENT_FIELDS = new List<String> {'Id', 'Project__c', 'Project__r.Name', 'Payment_Date__c', 'Payment_Amount__c', 'Contact__c'};
    public static final List<String> CONTACT_FIELDS = new List<String> {'Id', 'FirstName', 'LastName', 'Total_Payments__c', 'Last_Payment_Date__c'};
        
	public class Pager {

		@AuraEnabled
		public Integer total { get; set; }

		@AuraEnabled
		public Integer page { get; set; }

		@AuraEnabled
		public Integer size { get; set; }

		@AuraEnabled
		public Integer pages { get; set; }

		public Integer index_start { get; set; }

		public Integer index_end { get; set; }

		public Pager(Integer page_number, Integer page_total) {
			Integer total_pages = Integer.valueOf(Math.ceil(Decimal.valueOf(page_total) / PAGE_SIZE));
			page_number = (page_number == null || page_number < 1) ? 1 : page_number;
			page_number = total_pages < page_number ? total_pages : page_number;
			page_number = (page_number == null || page_number < 1) ? 1 : page_number;
			this.index_start = (page_number - 1) * page_size;
			this.index_end = this.index_start + page_size;
			this.index_end = this.index_end > page_total ? page_total : this.index_end;
			this.page = page_number;
			this.total = page_total;
			this.size = PAGE_SIZE;
			this.pages = total_pages;
		}
	}

	public class Section {

		@AuraEnabled
		public Contact person { get; set; }

		@AuraEnabled
		public List<Project_Payment__c> payments { get; set; }

		public Section(Contact c) {
			this.person = new Contact(
				Id = c.Id,
				FirstName = c.FirstName,
				LastName = c.LastName,
				Total_Payments__c = c.Total_Payments__c,
				Last_Payment_Date__c = c.Last_Payment_Date__c
			);
			this.payments = c.Project_Payment__r;
		}

	}

}