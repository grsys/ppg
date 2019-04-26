({
    init: function (component, event, helper) {
        if (component.get("v.severity") === 'confirm') {
            window.setTimeout(
                $A.getCallback(function() {
                    if (component.isValid()) {
                        component.set("v.isShowMessage", false);
                    }
                }), 2000
            );
        }
    },
	closeMessage : function(component, event, helper) {
		component.set("v.isShowMessage", false);
	}
})