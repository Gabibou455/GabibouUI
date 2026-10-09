-- Pure, engine-independent rules shared by the library and its tests.
local Logic = {}
function Logic.finite(value)
    return type(value)=="number" and value==value and math.abs(value)<math.huge
end
function Logic.number(value,minimum,maximum,step)
    assert(Logic.finite(value),"Value must be a finite number")
    assert(Logic.finite(minimum) and Logic.finite(maximum) and maximum>minimum,"Invalid slider range")
    assert(Logic.finite(step) and step>0,"Slider step must be positive")
    assert(Logic.finite(maximum-minimum) and Logic.finite((maximum-minimum)/step),"Slider range or step exceeds numeric precision")
    local bounded=math.clamp(value,minimum,maximum)
    local snapped=minimum+math.floor((bounded-minimum)/step+0.5)*step
    assert(Logic.finite(snapped),"Slider snap exceeds numeric range")
    return math.clamp(snapped,minimum,maximum)
end
function Logic.query(text)
    return string.lower(tostring(text or "")):match("^%s*(.-)%s*$")
end
function Logic.matches(text,query)
    for word in Logic.query(query):gmatch("%S+") do
        if not string.find(string.lower(text),word,1,true) then return false end
    end
    return true
end
function Logic.option(value,options)
    assert(type(value)=="string","Dropdown value must be a string")
    for _,option in ipairs(options) do if option==value then return value end end
    error("Unknown dropdown option: "..value)
end
function Logic.options(options)
    assert(type(options)=="table" and #options>0,"Dropdown needs at least one option")
    local seen={};local copy={}
    for _,option in ipairs(options) do
        assert(type(option)=="string" and option~="" and not seen[option],"Options must be unique, nonempty strings")
        seen[option]=true;copy[#copy+1]=option
    end
    return copy
end
function Logic.text(value,maximum)
    assert(type(value)=="string","Input value must be a string")
    assert(utf8.len(value)~=nil,"Input must contain valid UTF-8")
    if utf8.len(value)>maximum then return string.sub(value,1,(utf8.offset(value,maximum+1) or (#value+1))-1) end
    return value
end
function Logic.hex(value)
    assert(type(value)=="string","Color must be a six-digit hexadecimal string")
    local hex=value:match("^%s*#?(%x%x%x%x%x%x)%s*$")
    assert(hex,"Color must use #RRGGBB format")
    return "#"..string.upper(hex)
end
function Logic.profile(document,controls)
    assert(type(document)=="table" and document.version==1 and type(document.values)=="table","Invalid Gabibou UI profile")
    local staged={}
    for id,entry in pairs(document.values) do
        assert(type(id)=="string" and type(entry)=="table","Invalid profile entry")
        local control=controls[id]
        if control and control.Persistent then
            assert(entry.kind==control.Kind,"Profile type mismatch: "..id)
            staged[#staged+1]={control=control,value=control:_Validate(entry.value)}
        end
    end
    table.sort(staged,function(a,b)return a.control.Id<b.control.Id end)
    return staged
end
return Logic
