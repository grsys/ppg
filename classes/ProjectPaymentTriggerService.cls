public with sharing class ProjectPaymentTriggerService {

	public ProjectPaymentTriggerService() {}

	public static void handleChanges(List<Project_Payment__c> payments) {
		handleChanges(payments, NULL, true);
	}

	public static void handleChanges(List<Project_Payment__c> payments, Boolean isIncrementAmount) {
		handleChanges(payments, NULL, isIncrementAmount);
	}

	public static void handleChanges(List<Project_Payment__c> payments, List<Project_Payment__c> oldPayments) {
		handleChanges(payments, oldPayments, true);
	}

	public static void handleChanges(List<Project_Payment__c> payments, List<Project_Payment__c> oldPayments, Boolean isIncrementAmount) {

		Boolean isCalculateDelta = (oldPayments != NULL);
		Map<Id, Project_Payment__c> mapOldPayments = (isCalculateDelta) ?
			new Map<Id, Project_Payment__c>(oldPayments) :
			new Map<Id, Project_Payment__c>();

		List<Project__c> listProjectsToUpdate = new List<Project__c>();
		List<Contact> listContactsToUpdate = new List<Contact>();

		Map<Id, List<Project_Payment__c>> mapPaymentsByProjectId = new Map<Id, List<Project_Payment__c>>();
		Map<Id, List<Project_Payment__c>> mapPaymentsByContactId = new Map<Id, List<Project_Payment__c>>();

		Map<Id, Decimal> mapAmountByProjectId = new Map<Id, Decimal>();
		Map<Id, Decimal> mapAmountByContactId = new Map<Id, Decimal>();

		Map<Id, List<Date>> mapLastPaymentDateByProjectId = new Map<Id, List<Date>>();
		Map<Id, List<Date>> mapLastPaymentDateByContactId = new Map<Id, List<Date>>();

		Date timestamp = Date.today();

		for(Project_Payment__c payment : payments) {

			Id projectId = payment.Project__c;
			Id contactId = payment.Contact__c;

			Decimal paymentAmount = (payment.Payment_Amount__c == NULL) ? 0 : payment.Payment_Amount__c;
			if (isCalculateDelta) {
				Decimal oldAmountValue = mapOldPayments.get(payment.Id).Payment_Amount__c;
				oldAmountValue = (oldAmountValue == NULL) ? 0 : oldAmountValue;
				paymentAmount = (paymentAmount - oldAmountValue);
			}

			if (isIncrementAmount) {
				payment.Payment_Date__c = (payment.Payment_Date__c == NULL) ? timestamp : payment.Payment_Date__c;
			}

			Date paymentDate = payment.Payment_Date__c;

			List<Date> paymentDateProject = mapLastPaymentDateByProjectId.get(projectId);
			List<Date> paymentDateContact = mapLastPaymentDateByContactId.get(contactId);

			paymentDateProject = (paymentDateProject == NULL) ? new List<Date>() : paymentDateProject;
			paymentDateContact = (paymentDateContact == NULL) ? new List<Date>() : paymentDateContact;

			paymentDateProject.add(paymentDate);
			paymentDateContact.add(paymentDate);

			mapLastPaymentDateByProjectId.put(projectId, paymentDateProject);
			mapLastPaymentDateByContactId.put(contactId, paymentDateContact);

			Decimal totalAmountPerProject = mapAmountByProjectId.get(projectId);
			totalAmountPerProject = (totalAmountPerProject != NULL) ? totalAmountPerProject : 0;
			totalAmountPerProject += paymentAmount;
			mapAmountByProjectId.put(projectId, totalAmountPerProject);

			Decimal totalAmountPerContact = mapAmountByContactId.get(contactId);
			totalAmountPerContact = (totalAmountPerContact != NULL) ? totalAmountPerContact : 0;
			totalAmountPerContact += paymentAmount;
			mapAmountByContactId.put(contactId, totalAmountPerContact);

			List<Project_Payment__c> tmp = (mapPaymentsByProjectId.get(projectId) == NULL) ?
				new List<Project_Payment__c>() :
				mapPaymentsByProjectId.get(projectId);
			tmp.add(payment);
			mapPaymentsByProjectId.put(projectId, tmp);

			List<Project_Payment__c> tmp2 = (mapPaymentsByContactId.get(contactId) == NULL) ?
				new List<Project_Payment__c>() :
				mapPaymentsByContactId.get(contactId);
			tmp2.add(payment);
			mapPaymentsByContactId.put(contactId, tmp2);

		}

		List<Project__c> listProjects = [
			SELECT Id, Last_Payment_Date__c, Total_Payments__c
			FROM Project__c
			WHERE Id IN :mapAmountByProjectId.keySet()
			LIMIT 200
		];

		List<Contact> listContacts = [
			SELECT Id, Last_Payment_Date__c, Total_Payments__c
			FROM Contact
			WHERE Id IN :mapPaymentsByContactId.keySet()
			LIMIT 200
		];

		Map<Id, Date> mapNewLastPaymentDateByProjectId = new Map<Id, Date>();
		Map<Id, Date> mapNewLastPaymentDateByContactId = new Map<Id, Date>();

		if (!isIncrementAmount) {
			AggregateResult[] lastPaymentDateForProject = [
				SELECT Project__c,  MAX(Payment_Date__c)lastPaymentDate
		      	FROM Project_Payment__c
		      	WHERE Project__c IN :mapAmountByProjectId.keySet()
		      	GROUP BY Project__c
		    ];

		    for (AggregateResult ar : lastPaymentDateForProject) {
		    	Id projectId = (Id)ar.get('Project__c');
		    	Date lastPaymentDate = (Date)ar.get('lastPaymentDate');
		    	mapNewLastPaymentDateByProjectId.put(projectId, lastPaymentDate);
		    }

		    AggregateResult[] lastPaymentDateForContact = [
				SELECT Contact__c,  MAX(Payment_Date__c)lastPaymentDate
		      	FROM Project_Payment__c
		      	WHERE Contact__c IN :mapPaymentsByContactId.keySet()
		      	GROUP BY Contact__c
		    ];

		    for (AggregateResult ar : lastPaymentDateForContact) {
		    	Id contactId = (Id)ar.get('Contact__c');
		    	Date lastPaymentDate = (Date)ar.get('lastPaymentDate');
		    	mapNewLastPaymentDateByContactId.put(contactId, lastPaymentDate);
		    }

		}


		for(Project__c project : listProjects) {
			Decimal totalAmount = (project.Total_Payments__c != NULL) ? project.Total_Payments__c : 0;

			// Last Payment Day
			if (isIncrementAmount) {
				Date currentlastPaymentDate = project.Last_Payment_Date__c;
				List<Date> paymentDate = mapLastPaymentDateByProjectId.get(project.Id);
				paymentDate.sort();

				Date lastPaymentDate = paymentDate.get(paymentDate.size() - 1);
				if((currentlastPaymentDate == NULL) || lastPaymentDate > currentlastPaymentDate) {
					project.Last_Payment_Date__c = lastPaymentDate;
				}
			}
			else {
				Date lastPaymentDate = mapNewLastPaymentDateByProjectId.get(project.Id);
				project.Last_Payment_Date__c = lastPaymentDate;
			}

			// Amount
			if (mapAmountByProjectId.containsKey(project.Id)) {
				Decimal additionalAmount = mapAmountByProjectId.get(project.Id);
				project.Total_Payments__c = (isIncrementAmount) ?
					totalAmount + additionalAmount:
					totalAmount - additionalAmount;

				listProjectsToUpdate.add(project);
			}
		}

		for(Contact contact : listContacts) {
			Decimal totalAmount = (contact.Total_Payments__c != NULL) ? contact.Total_Payments__c : 0;

			// Last Payment Day
			if (isIncrementAmount) {
				Date currentlastPaymentDate = contact.Last_Payment_Date__c;
				List<Date> paymentDate = mapLastPaymentDateByContactId.get(contact.Id);
				paymentDate.sort();

				Date lastPaymentDate = paymentDate.get(paymentDate.size() - 1);
				if((currentlastPaymentDate == NULL) || lastPaymentDate > currentlastPaymentDate) {
					contact.Last_Payment_Date__c = lastPaymentDate;
				}
			}
			else {
				Date lastPaymentDate = mapNewLastPaymentDateByContactId.get(contact.Id);
				contact.Last_Payment_Date__c = lastPaymentDate;
			}

			if (mapAmountByContactId.containsKey(contact.Id)) {
				Decimal additionalAmount = mapAmountByContactId.get(contact.Id);
				contact.Total_Payments__c = (isIncrementAmount) ?
					totalAmount + additionalAmount:
					totalAmount - additionalAmount;

				listContactsToUpdate.add(contact);
			}
		}


		/*
		* Handle DML Exception when unable to obtain exclusive access to this record (UNABLE_TO_LOCK_ROW)
		* Prevent commit records to base to ensure the consistency of amount
		*/
		if (!listProjectsToUpdate.isEmpty()) {
			List<Database.SaveResult> saveResults = Database.update(listProjectsToUpdate, false);
			for(Integer i = 0; i < saveResults.size(); i++){
				if (!saveResults.get(i).isSuccess()) {
					Id failedProjectId = listProjectsToUpdate.get(i).Id;

					List<Project_Payment__c> tmp = mapPaymentsByProjectId.get(failedProjectId);
					for (Project_Payment__c pp : tmp) {
						pp.addError('Error: Unable to obtain exclusive access to the Project record ' + failedProjectId);
					}
				}
			}
		}

		/*
		* Handle DML Exception when unable to obtain exclusive access to this record (UNABLE_TO_LOCK_ROW)
		* Prevent commit records to base to ensure the consistency of amount
		*/
		if (!listContactsToUpdate.isEmpty()) {
			List<Database.SaveResult> saveResults = Database.update(listContactsToUpdate, false);
			for(Integer i = 0; i < saveResults.size(); i++){
				if (!saveResults.get(i).isSuccess()) {
					Id failedContactId = listContactsToUpdate.get(i).Id;

					List<Project_Payment__c> tmp = mapPaymentsByContactId.get(failedContactId);
					for (Project_Payment__c pp : tmp) {
						pp.addError('Error: Unable to obtain exclusive access to the Contact record ' + failedContactId);
					}
				}
			}
		}

	}
}