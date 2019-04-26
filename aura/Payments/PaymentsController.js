({
	init: function(component, event, helper) {
		helper.getPayments(component);
		helper.getProjects(component);
	},
	setPage: function(component, event, helper) {
		var pageNumber = event.getSource().get('v.name');
		var pagination = component.get('v.pagination');
		if (pageNumber == -1) {
			pageNumber = pagination.pageNumber - 1;
		}
		else if (pageNumber == -2) {
			pageNumber = pagination.pageNumber + 1;
		}
		helper.getPayments(component, parseInt(pageNumber));
	},
	setOrder: function(component, event, helper) {
		var value = event.currentTarget.dataset.value;
		var page = component.get('v.page');
		if (
			!page.orderBy
			|| page.orderBy.indexOf(value) == -1
			|| page.orderBy.indexOf('ASC') == -1
		) {
			page.orderBy = value + ' ASC';
		}
		else {
			page.orderBy = value + ' DESC';
		}
		helper.getPayments(component);
	},
	changeSearchText: function(component, event, helper) {
        //debounce handling, so that we don't hit the back end everytime user presses a key
		if (!helper.debounceCounter) {
			helper.debounceCounter = 0;
		}
		helper.debounceCounter++;
		setTimeout($A.getCallback(function() {
			helper.debounceCounter--;
			if (helper.debounceCounter < 1) {
				helper.debounceCounter = 0;
				helper.getPayments(component, 1, true);
			}
		}), 500);
	},
	addPayment: function(component, event, helper) {
		var index = event.getSource().get('v.name');
		var page = component.get('v.page');
		var sections = page.sections;
		var section;
		for (var i = 0, len = sections.length; i < len; i++) {
			if (i == index) {
				section = sections[i];
			}
		}
		if (section) {
			section.payments.unshift({
				edit: true,
				Payment_Date__c: new Date().toISOString().substring(0,10),
				Payment_Amount__c: null,
				Project__c: null,
				Contact__c: section.person.Id
			})
		}
		component.set('v.page',page);
	},
	editPayment: function(component, event, helper) {
		var index = event.getSource().get('v.name');
		var page = component.get('v.page');
		var sections = page.sections;
		var payment = helper.find(sections, index);
		if (payment) {
			payment.edit = true;
			payment.Payment_Date__backup = payment.Payment_Date__c;
			payment.Payment_Amount__backup = payment.Payment_Amount__c;
		}
		component.set('v.page',page);
	},
	deletePayment: function(component, event, helper) {
		var index = event.getSource().get('v.name');
		var page = component.get('v.page');
		var sections = page.sections;
		var payment = helper.find(sections, index);
		var action = component.get('c.remove');
		action.setParams({
			paymentId: payment.Id
		});
		action.setCallback(this, function(response) {
			component.set('v.loading',false);
			if (response.getState() == 'ERROR') {
				component.set('v.message', response.getError()[0]);
				component.set('v.severity', 'error');
				component.set('v.isShowMessage', true);
			}
			else if (response.getState() == 'SUCCESS') {
				var resultSection = response.getReturnValue();
				helper.updatePerson(sections, resultSection, index);
				helper.remove(sections, index);
				component.set('v.page', page);
			}
		});
		$A.enqueueAction(action);
		component.set('v.loading',true);
	},
	savePayment: function(component, event, helper) {
		var index = event.getSource().get('v.name');
		var page = component.get('v.page');
		var sections = page.sections;
		var payment = helper.find(sections, index);

		if (
			!payment.Payment_Date__c
			|| (!payment.Payment_Amount__c && payment.Payment_Amount__c != 0)
			|| !payment.Project__c
		) {
			component.set('v.message', 'Please complete all payment fields');
			component.set('v.severity', 'error');
			component.set('v.isShowMessage', true);
			return;
		}

		var action = component.get('c.save');
		action.setParams({
			payment: {
				Id: payment.Id || null,
				Payment_Date__c: payment.Payment_Date__c,
				Payment_Amount__c: payment.Payment_Amount__c,
				Project__c: payment.Project__c,
				Contact__c: payment.Contact__c
			}
		});
		action.setCallback(this, function(response) {
			component.set('v.loading',false);
			if (response.getState() == 'ERROR') {
				component.set('v.message', response.getError()[0]);
				component.set('v.severity', 'error');
				component.set('v.isShowMessage', true);
			}
			else if (response.getState() == 'SUCCESS') {
				if (!payment.Id) {
					var projects = component.get('v.projects');
					projects.forEach(function(p) {
						if (p.Id == payment.Project__c) {
							payment.Project__r = { Name: p.Name }
						}
					});
				}
				var resultSection = response.getReturnValue();
				helper.updatePerson(sections, resultSection, index);
				payment.Id = resultSection.payments[0].Id;
				payment.edit = false;
				component.set('v.page',page);
			}
		});
		$A.enqueueAction(action);
		component.set('v.loading',true);
	},
	cancelEditPayment: function(component, event, helper) {
		var index = event.getSource().get('v.name');
		var page = component.get('v.page');
		var sections = page.sections;
		var payment = helper.find(sections, index);
		if (!payment.Id) {
			var indexParts = index.split('-');
			helper.remove(sections, index);
		}
		else {
			payment.edit = false;
			payment.Payment_Date__c = payment.Payment_Date__backup;
			payment.Payment_Amount__c = payment.Payment_Amount__backup;
		}
		component.set('v.page',page);
	},
	showHideChilds: function(component, event, helper) {
		var index = event.getSource().get('v.name');
		var page = component.get('v.page');
		var sections = page.sections;
		var isParentsCollapsed = component.get('v.isParentsCollapsed');
		if (index === '-1') {
			isParentsCollapsed = !isParentsCollapsed;
			sections.forEach(function(s) {
				s.collapsed = isParentsCollapsed;
			});
			component.set('v.isParentsCollapsed',isParentsCollapsed);
		}
		else {
			for(var i = 0, len = sections.length; i < len; i++) {
				if (i == index) {
					sections[i].collapsed = !sections[i].collapsed;
				}
			}
		}
		component.set('v.page',page);
	},
})