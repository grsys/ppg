public with sharing class TriggerFactory {
    
    public static void executeHandler(Type t) {
        
        TriggerHandler handler = getHandler(t);
         
        if (handler == null) {
            throw new TriggerException('No Trigger Handler found named: ' + t.getName());
        }
        
        execute(handler);
    }
 
    private static void execute(ITrigger handler) {
        
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                handler.bulkBeforeInsert(Trigger.new);                
            }
            else if (Trigger.isUpdate) {
                handler.bulkBeforeUpdate(Trigger.old, Trigger.new);                
            }
            else if (Trigger.isDelete) {
                handler.bulkBeforeDelete(Trigger.old);                
            }           
        }
        else {
            if (Trigger.isInsert) {
                handler.bulkAfterInsert(Trigger.new);
            }
 			else if (Trigger.isUpdate) {
                handler.bulkAfterUpdate(Trigger.old, Trigger.new);
            }
            else if (Trigger.isDelete) {
                handler.bulkAfterDelete(Trigger.old);
            }            
        } 
    }
 
    private static TriggerHandler getHandler(Type t) {
        
        Object o = t.newInstance();
 
        if (!(o instanceOf TriggerHandler)) {
            return null;
        }
 
        return (TriggerHandler)o;
    }
 
    public class TriggerException extends Exception {}
}