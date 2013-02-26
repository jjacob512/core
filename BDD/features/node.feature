Feature: Nodes
  In order check out the nodes
  The system operator, Oscar
  wants to be able to check the status of nodes

  Scenario: Nodes List
    When REST gets the {object:node} list
    Then there should be a value {lookup:node.name}

  Scenario: REST JSON check
    When REST gets the {object:node} {lookup:node.name}
    Then the {object:node} is properly formatted
    
  Scenario: REST Can Delete
    Given REST creates the {object:node} "going.going.gone"
    When REST deletes the {object:node} "going.going.gone"
    Then I get a {integer:200} result
      And there is not a {object:node} "going.going.gone"
  
  Scenario: REST Get 404
    When REST gets the {object:node} "thisdoesnotexist"
    Then I get a {integer:404} error
    
  Scenario: Status Empty
    When AJAX requests the "/framework/status/nodes" page
    Then key "sum" should be a number
      And there should be a key "state"
      And there should be a key "status"
      And there should be a key "groups"
      And there should be a key "i18n"
      And there should be a key "count"
      And key "[groups][0]" should contain "7" items

  Scenario: Status Non Nodes
    When AJAX requests the "/framework/status/nodes/0" page
    Then key "sum" should be a number
      And there should be a key "state"
      And there should be a key "status"
      And there should be a key "groups"
      And there should be a key "i18n"
      And there should be a key "count"
      And key "count" should be "0"
      And key "[groups][0]" should contain "7" items
      
  Scenario: Node List
    Given there is a {object:node} "bdd-node-list.example.com"
    When REST gets the {object:node} list
    Then there should be a value "bdd-node-list.example.com"
      And there should be a value "bdd1.example.com"
      And there should be a value "global-node.testing.com"
    Finally REST removes the node "bdd-node-list.example.com"
    
  Scenario: Node Detail
    When I go to the "dashboard/node/bdd1.example.com" page
    Then I should see "Full Name"
      And I should see "State"
      And I should see "Uptime"
      And I should see "Switch"
      And I should see "MAC Address"
      And I should see "Allocated"
      And I should see "Description"
      And I should see "Memory"
      And I should see "Disk Drives"
      And I should see a link to "Edit"
      And there should be no translation errors

  Scenario: Node Detail REST
    When REST gets the {object:node} "bdd1.example.com"
    Then key "fingerprint" should be a number
      And there should be a key "state"
      And there should be a key "name"
      And there should be a key "description"
      And there should be a key "created_at"
      And there should be a key "os_id"
      And there should be a key "id"
      And key "id" should be a number
      And there should be a key "order"
      And key "order" should be a number
      And there should be a key "updated_at"
      And the {object:node} is properly formatted

  Scenario: Node Attribute List Works
    Skip work out attrib node pattern
    Given {object:node} "bdd1.example.com" has {object:attrib_type} "bddtest1"
    When REST gets the node-attribute list for "bdd1.example.com"
    Then id {object:attrib_type} should have value {lookup:attrib.value}
    Finally REST unassigns {object:attrib_type} "bddtest1" from {object:node} "bdd1.example.com"

  Scenario: Node Attribute Get Value
    Skip work out attrib node pattern
    Given {object:node} "node1.attribute.com" with {object:attrib_type} "bdd1test" has value "foo"
    When REST gets the {object:node} "node1.attribute.com" with {object:attrib_type} "bdd1test"
    Then there is a key "value"
      And key "value" should be "foo"
    Finally REST removes {object:node} "node1.attribute.com"
      And REST removes {object:attrib_type} "bdd1test"  
      
  Scenario: Node Assign Attribute
    Skip work out attrib node pattern
    Given there is a {object:node} "node2.attribute.com"
      And there is a {object:attrib_type} "bdd2test"
    When REST assigns {object:attrib_type} "bdd2test" to {object:node} "node2.attribute.com"
    Then the result is a valid node-attribute json
      And {object:node} "node2.attribute.com" has {object:attrib_type} "bdd2test"
    Finally REST unassigns {object:attrib_type} "bddtest1" from {object:node} "bdd1.example.com"
      And REST removes {object:node} "node2.attribute.com"
      And REST removes {object:attrib_type} "bdd2test"  
  
  Scenario: Node Remove Attribute
    Skip work out attrib node pattern
    Given {object:node} {lookup:node.name} has {object:attrib_type} "bdd3test"
    When REST unassigns {object:attrib_type} "bdd3test" from {object:node} {lookup:node.name}
    Then the page returns "200"
      And {object:node} {lookup:node.name} has no {object:attrib_type} "bdd3test"
    Finally REST removes {object:attrib_type} "bdd3test"  

  Scenario: Node can Update Attribute
    Skip work out attrib node pattern
    Given {object:node} {lookup:node.name} adds {object:attrib_type} "bdd4test" with value "foofoofoo"
    When {object:node} {lookup:node.name} with {object:attrib_type} "bdd4test" is set to value "barbarbar"
    Then the page returns "200"
      And key "value" should be "barbarbar"
      And key "value" should not be "foofoofoo"
    Finally REST removes {object:attrib_type} "bdd4test"
