local Converter = require "@self/Converter"
task.wait(2)
local test = Converter:ConvertInstance(workspace.Part)
print(test)
local out = Converter:ToFusionComponent(test)
print(out)
