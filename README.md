# Introduction 
This is a behaviour tree plugin for Lua. Create a tree of nodes and have the process function decide what to do every run. There's different kinds of nodes that link to each other. Each node returns a status(success, failure or running) on every run. The tree tries to find a path through the collection of nodes by following roads through nodes that return a success. This plugin has different kinds of nodes:

- Leaf nodes that run a function which will return a status.
- Selector nodes that return success if any of their child nodes returns success.
- Prio-Selectors to the same as Selectors, but decide the order of trying to run the nodes based on a priority value.
- Sequence nodes that return success if all of their nodes return success in order.
- Dep-Sequences do the samen as Sequences, but only if a defined dependency tree (a set of nodes) returns success every time it runs.
- Repeater nodes repeat a child a given number of times, of infinitely.
- Dep-Repeater nodes repeat a child for as long as the dependency tree returns success.
- Inverter nodes swap success and failure for the child node
- Succeeder nodes always return success
- Failer nodes always return failure
- Runner nodes always return running


# How to use

First require the lua file to a variable
``local BT = require ("bt)``

We want to create this basic tree for automating eating:
![A simple behaviour tree flowchart](https://github.com/Xrocetoxtos/Lua-BT/blob/main/bt%20example.jpg)

First we create the nodes from the bottom up. We need Leaf nodes for the bottom row and the one in the middle:
```
local haveFood = BT.leaf("Do I have food?", 1, checkCabinet, nil)
local prepareFood = BT.leaf("Prepare food", 1, prepareFood, nil)
local eat = BT.leaf(Eat", 1, eat, nil)
local haveMoney = BT.leaf("Do I have money?", 1, checkWallet, nil)
local orderFood = BT.leaf("Order money?", 1, orderFood, nil)
local wait = BT.leaf("Wait",1,wait, nil)
```

Two remarks here:
- the eat Leaf will be used twice, but only needs to be there once
- The different Leaf nodes have a function in their 3rd argument. This function needs to exist and needs to be defined above the call of the BT.leaf. It needs to return Status.SUCCESS, Status.FAILURE or Status.RUNNING.

An example of a function for checking if we have money:
```
local haveMoney = function(args)
  return BT.boolToStatus(money > amountNeeded)
end
```

The variables money and amountNeeded need to be defined of course.

Next, we need to define the middle row of nodes, the Sequence nodes. We add the Leaf nodes we created as children to these new Sequence nodes:
```
local prepareSequence = BT.sequence ("Prepare sequence", 1, {haveFood, prepareFood, eat})
local orderSequence = BT.sequence ("Order sequence", 1, {haveMoney, orderFood, eat})
```

Finally we link al of it together with the top Selector node:
```
local tree = BT.selector("Tree", 1, { prepareSequence, orderSequence, wait})
```

Any time we run ``tree.process()``, the behaviour tree will try to find a way through the tree. If there is food, it'll run the prepareFood Sequence in order. If there is no food, but there is money, it'll run orderFood. Otherwise it'll run wait. Wait might return Running for as long as is defined or just finish the process.

# Functions
## Creating nodes
- **bt.leaf** creates a Leaf node. Arguments are the name, priority, function and arguments(as a table).
- **bt.selector** creates a Selector node. Arguments are name, priority and children(as a table).
- **bt.prioSelector** creates a Prio-Selector node. Arguments are name, priority and children(as a table).
- **bt.sequence** creates a Sequence node. Arguments are name, priority and children(as a table).
- **bt.depSequence** creates a Dep-Sequence node. Arguments are name, priority, children(as a table) and a dependancy node.
- **bt.inverter** creates a Invertor node. Arguments are name, priority and one child node.
- **bt.repeater** creates a Repeater node. Arguments are name, priority, one child node and the number of times it needs to repeat (-1 is infinite).
- **bt.depRepeater** creates a Dep-Repeater node. Arguments are name, priority, one child node and a dependency node.
- **bt.runner** creates a Runner node. Arguments are name and priority.
- **bt.succeeder** creates a Succeeder node. Arguments are name and priority.
- **bt.failer** creates a Failer node. Arguments are name and priority.

## Working with nodes
- **node.debug** writes a visual representation of the node and its children to the console. Argument is a level to decide the indentation.
- **node.displayName** for debugging, returns the name, node type and a unique id.
- **node.process** is the bread and butter of the plugin. It'll run the node and returns the status you need it to return. It'll also run child nodes and dependency nodes if needed.

## Utilities
- **bt.boolToStatus** takes a boolean value and returns Status.SUCCESS if true and Status.FAILURE if false.
- **bt.priorityCompare** is used to sort nodes based on the priority, for Prio-Selectors only.
