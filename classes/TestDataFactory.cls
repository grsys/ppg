public class TestDataFactory {

	public List<Contact> contacts;
	public List<Project__c> projects;
	public List<Project_Payment__c> payments;

	public TestDataFactory() {

	}

	private static final String ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

	public String generateRandomString(Integer len) {
		String randStr = '';
		while (randStr.length() < len) {
			Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), ALPHABET.length());
			randStr += ALPHABET.substring(idx, idx+1);
		}
		return randStr;
	}

	public void regularInit(Integer numberOfContacts, Integer numberOfProjects) {
        regularInit(numberOfContacts, numberOfProjects, 1);
    }

    public void regularInit(Integer numberOfContacts, Integer numberOfProjects, Integer numberOfPayments) {
		Account testAccount = new Account(Name = this.generateRandomString(8));
		insert testAccount;

		this.contacts = new List<Contact>();
		for (Integer i = 0; i < numberOfContacts; i++) {
			this.contacts.add(new Contact(
				FirstName = this.generateRandomString(6),
				LastName = this.generateRandomString(6),
				AccountId = testAccount.Id
			));
		}
		insert this.contacts;

		this.projects = new List<Project__c>();
		for (Integer j = 0; j < numberOfProjects; j++) {
			this.projects.add(new Project__c(
				Name = this.generateRandomString(8)
			));
		}
		insert this.projects;

		Integer i = 100;
		Date d = Date.today().addYears(-1);
		this.payments = new List<Project_Payment__c>();
		for (Contact c : this.contacts) {
            for (Project__c p : this.projects) {
                for (Integer k = 0; k < numberOfPayments; k++) {
                    Project_Payment__c pp = new Project_Payment__c(
                        Project__c = p.Id,
                        Payment_Date__c = d,
                        Payment_Amount__c = i,
                        Contact__c = c.Id
                    );
				    this.payments.add(pp);
                }
				d = d.addDays(1);
			}
		}
		insert this.payments;
	}

}