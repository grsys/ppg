public interface ITrigger {
	
	void bulkBeforeInsert(List<SObject> soList);
	
	void bulkBeforeUpdate(List<SObject> oldSoList, List<SObject> soList);

	void bulkBeforeDelete(List<SObject> soList);

	void bulkAfterInsert(List<SObject> soList);

	void bulkAfterUpdate(List<SObject> oldSoList, List<SObject> soList);

	void bulkAfterDelete(List<SObject> soList);

}