Status = {
    RUNNING = "RUNNING",
    SUCCESS = "SUCCESS",
    FAILURE = "FAILURE",
    IDLE = "IDLE"
}

NodeType = {
    NODE = "NODE",
    LEAF = "LEAF",
    SUCCEEDER = "SUCCEEDER",
    FAILER = "FAILER",
    RUNNER = "RUNNER",
    INVERTER = "INVERTER",
    SELECTOR = "SELECTOR",
    PRIO_SELECTOR = "PRIO_SELECTOR",
    SEQUENCE = "SEQUENCE",
    DEP_SEQUENCE = "DEP_SEQUENCE",
    REPEATER = "REPEATER",
    DEP_REPEATER = "DEP_REPEATER",
}

local bt={}

    bt.id = 0
    bt.activeNode = nil

    function bt.leaf(name, priority, func, args)
        local leaf = bt.new(name, NodeType.LEAF, priority)
        leaf.addFunction(func, args)
        return leaf
    end

    function bt.selector(name, priority, children)
        local selector = bt.new(name, NodeType.SELECTOR, priority)
        for index, child in ipairs(children) do
            selector.addChild(child)
        end
        return selector
    end

    function bt.prioSelector(name, priority, children)
        local pselector = bt.new(name, NodeType.PRIO_SELECTOR, priority)
        for index, child in ipairs(children) do
            pselector.addChild(child)
        end
        return pselector
    end

    function bt.sequence(name, priority, children)
        local sequence = bt.new(name, NodeType.SEQUENCE, priority)
        for index, child in ipairs(children) do
            sequence.addChild(child)
        end
        return sequence
    end

    function bt.depSequence(name, priority, children, dependancy)
        local dep_sequence = bt.new(name, NodeType.DEP_SEQUENCE, priority)
        for index, child in ipairs(children) do
            dep_sequence.addChild(child)
        end
        dep_sequence.dependancy = dependancy

        return dep_sequence
    end

    function bt.inverter(name, priority, child)
        local inverter = bt.new(name, NodeType.INVERTER, priority)
        inverter.addChild(child)
        return inverter
    end
    
    function bt.repeater(name, priority, child, times)
        local repeater = bt.new(name, NodeType.REPEATER, priority)
        repeater.addChild(child)
        repeater.repeatTimes = times
        return repeater
    end

    function bt.depRepeater(name, priority, child, dependancy)
        local repeater = bt.new(name, NodeType.DEP_REPEATER, priority)
        repeater.addChild(child)
        repeater.dependancy = dependancy
        return repeater
    end

    function bt.runner(name, priority)
        local runner = bt.new(name, NodeType.RUNNER, priority)
        return runner
    end   
    
    function bt.succeeder(name, priority)
        local runner = bt.new(name, NodeType.SUCCEEDER, priority)
        return runner
    end   
    
    function bt.failer(name, priority)
        local runner = bt.new(name, NodeType.FAILER, priority)
        return runner
    end    

    function bt.new(name, nodetype, priority)
        local node = {}

            node.name = name
            node.children = {}
            node.nodetype = nodetype
            node.priority = priority
            node.currentChild = 1

            node.dependancy = nil
            node.repeatTimes = 0 -- -1 = infinite
            node.repeated = 0

            node.id = bt.id
            bt.id = bt.id + 1

            node.status = Status.IDLE

            node.addDependancy = function (dependancy)
                node.dependancy = dependancy
            end

            node.addFunction = function(func, args)
                node.func = func
                node.args = args
            end

            node.addChild = function(child)
                table.insert(node.children, child)
            end
    -- ----------------------------------------------------------
            node.debug = function(level)
                local line = ""
                for i = 1, level, 1 do
                    line=line.."-"
                end

                line = line.." "..node.displayName()
                print(line)

                level=level+1
                if node.dependancy ~= nil then
                    local depLine = ""
                    for i = 1, level, 1 do
                        depLine = depLine .. "*"
                    end
                    print(depLine .. " ** dependancy **")
                    node.dependancy.debug(level)
                    print(depLine .. "/** dependancy **/")
                end

                for index, child in ipairs(node.children) do
                    child.debug(level)
                end
            end

            node.displayName = function ()
                return node.name.. "["..node.nodetype.."] - ID: ".. node.id
            end
    -- ----------------------------------------------------------
            node.process = function()

                bt.activeNode = node
                if node.func then
                    return node.func(node.args)
                end
                local status = node.processDecorator()
                if status == nil then
                    print("no process for ".. node.displayName())
                    return Status.IDLE
                end
                return status
            end

            node.processDecorator = function ()
                if node.nodetype == NodeType.SUCCEEDER then return Status.SUCCESS end
                if node.nodetype == NodeType.FAILER then return Status.FAILURE end
                if node.nodetype == NodeType.RUNNER then return Status.RUNNING end

                if node.nodetype == NodeType.SELECTOR or node.nodetype == NodeType.PRIO_SELECTOR then
                    if node.nodetype == NodeType.PRIO_SELECTOR then
                        table.sort(node.children, bt.priorityCompare)
                    end
                    return node.processSelector()
                end
                if node.nodetype == NodeType.SEQUENCE or node.nodetype == NodeType.DEP_SEQUENCE then
                    return node.processDepSequence()
                end
                if node.nodetype == NodeType.INVERTER then
                    return node.inverterProcess()
                end
                if node.nodetype == NodeType.REPEATER then
                    return node.repeaterProcess()
                end
                if node.nodetype == NodeType.DEP_REPEATER then
                    return node.depRepeater()
                end
                print("no process type")
            end

            node.processSelector = function ()
                if #node.children<= 0 then
                    print("no children for ".. node.displayName())
                    return Status.FAILURE
                end
                local childStatus = node.children[node.currentChild].process()

                if childStatus == Status.RUNNING then 
                    return Status.RUNNING 
                end
                if childStatus == Status.SUCCESS then
                    node.currentChild = 1
                    return Status.SUCCESS
                end
            
                node.currentChild = node.currentChild + 1
            
                if node.currentChild > #node.children then
                    node.currentChild = 1
                    return Status.FAILURE
                end
                return Status.RUNNING
            end

            node.processSequence = function ()
                if #node.children<= 0 then
                    print("no children for ".. node.displayName())
                    return Status.FAILURE
                end
                local childStatus = node.children[node.currentChild].process()

                if childStatus == Status.RUNNING then 
                    return Status.RUNNING 
                end
                if childStatus == Status.FAILURE then
                    node.currentChild = 1
                    return Status.FAILURE
                end
            
                node.currentChild = node.currentChild + 1
                if node.currentChild > #node.children then
                    node.currentChild = 1
                    return Status.SUCCESS
                end
                return Status.RUNNING   
            end

            node.processDepSequence = function ()
                if #node.children<= 0 then
                    print("no children for ".. node.displayName())
                    return Status.FAILURE
                end
                local dependancyStatus = Status.SUCCESS
                if node.nodetype == NodeType.DEP_SEQUENCE then
                    dependancyStatus = node.dependancy.process()
                end

                if dependancyStatus == Status.SUCCESS then
                    return node.processSequence()
                end
                return Status.FAILURE  
            end

            node.inverterProcess = function ()
                if #node.children~= 1 then
                    print("not one child for ".. node.displayName())
                    return Status.FAILURE
                end         
                local childStatus = node.children[1].process()
                if childStatus == Status.RUNNING then return Status.RUNNING end
                if childStatus == Status.FAILURE then return Status.SUCCESS end
                if childStatus == Status.SUCCESS then return Status.FAILURE end
            end

            node.repeaterProcess = function ()
                if #node.children~= 1 then
                    print("not one child for ".. node.displayName())
                    return Status.FAILURE
                end
                local childStatus = node.children[1].process()
                if childStatus ~= Status.RUNNING then
                    if node.repeatTimes == -1 or node.repeatTimes > node.repeated then
                        node.repeated = node.repeated + 1
                        return Status.RUNNING
                    else
                        node.currentChild = 1
                        node.repeated = 0
                        return childStatus
                    end
                end
                return Status.RUNNING
            end

            node.depRepeaterProcess = function ()
                if #node.children~= 1 then
                    print("not one child for ".. node.displayName())
                    return Status.FAILURE
                end
                local dependancyStatus = node.dependancy.process()
                if dependancyStatus == Status.SUCCESS then
                    return node.children[1].process()
                end
                return Status.FAILURE
            end

        return node
    end

    function bt.boolToStatus(b)
        if b == true then
            return Status.SUCCESS
        end
        return Status.FAILURE
    end
    
    function bt.priorityCompare(a,b)
        return a.priority < b.priority
    end

return bt