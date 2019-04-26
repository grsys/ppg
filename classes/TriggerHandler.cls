public virtual class TriggerHandler implements ITrigger {
	
	public TriggerHandler() {
		System.debug(LoggingLevel.ERROR, '--TriggerHandler--');
	}

	public virtual void bulkBeforeInsert(List<SObject> soList) {}
	
	public virtual void bulkBeforeUpdate(List<SObject> oldSoList, List<SObject> soList) {}

	public virtual void bulkBeforeDelete(List<SObject> soList) {}

	public virtual void bulkAfterInsert(List<SObject> soList) {}

	public virtual void bulkAfterUpdate(List<SObject> oldSoList, List<SObject> soList) {}

	public virtual void bulkAfterDelete(List<SObject> soList) {}

}