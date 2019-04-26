({
	getPayments: function(component, pageNumber, searching) {
		var helper = this;
		var action = component.get('c.getPayments');
		var page = component.get('v.page') || {};
		page.sections = null;
		if (searching) {
			page.orderBy = null;
		}
		if (pageNumber) {
			page.pagination.page = pageNumber;
		}
		action.setParams({
			page: JSON.stringify(page)
		});
		action.setCallback(this, function(response) {
			if (response.getState() != 'SUCCESS') return;
			var responsePage = response.getReturnValue();
			component.set('v.page', response.getReturnValue());
			helper.setupPagination(component, responsePage.pagination);
			if (searching) {
				component.set('v.searching', false);
			}
			else {
				component.set('v.loading', false);
			}
		});
		$A.enqueueAction(action);
		if (searching) {
			component.set('v.searching', true);
		}
		else {
			component.set('v.loading', true);
		}
	},
	getProjects: function(component) {
		var action = component.get('c.getProjects');
		action.setCallback(this, function(response) {
			if (response.getState() != 'SUCCESS') return;
			component.set('v.projects', response.getReturnValue());
		});
		$A.enqueueAction(action);
	},
	setupPagination: function(component, incoming) {
		var calculated = {
			show: incoming.pages > 1,
			pageNumber: incoming.page,
			pages: [],
			previous: incoming.page > 1,
			next: incoming.page < incoming.pages
		}
		for (var z = 1; z <= incoming.pages; z++) {
			calculated.pages.push({
				number: z,
				active: incoming.page == z
			});
		}
		component.set('v.pagination', calculated);
	},
	find: function(sections, index) {
		var indexParts = index.split('-');
		var payment;
		for (var i = 0, len = sections.length; i < len; i++) {
			if (i == indexParts[0]) {
				for (var j = 0, pen = sections[i].payments.length; j < pen; j++) {
					if (j == indexParts[1]) {
						payment = sections[i].payments[j]
					}
				}
			}
		}
		return payment;
	},
	remove: function(sections, index) {
		var indexParts = index.split('-');
		var section;
		for (var i = 0, len = sections.length; i < len; i++) {
			if (i == indexParts[0]) {
				var filteredPayments = [];
				for (var j = 0, pen = sections[i].payments.length; j < pen; j++) {
					if (j != indexParts[1]) {
						filteredPayments.push(sections[i].payments[j]);
					}
				}
				sections[i].payments = filteredPayments;
			}
		}
	},
	updatePerson: function(sections, resultSection, index) {
		var indexParts = index.split('-');
		for (var i = 0, len = sections.length; i < len; i++) {
			if (i == indexParts[0]) {
				sections[i].person.Total_Payments__c = resultSection.person.Total_Payments__c;
				sections[i].person.Last_Payment_Date__c = resultSection.person.Last_Payment_Date__c;
			}
		}
	}
})