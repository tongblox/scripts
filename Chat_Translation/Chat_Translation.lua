--[[
    AI Message Translator
    Made by Aim, updated by evn and tongblx
    AI版本修改版 - 支持多种AI API
    默认使用DeepSeek API
--]]

if not game['Loaded'] then game['Loaded']:Wait() end; repeat wait(.06) until game:GetService('Players').LocalPlayer ~= nil

-- 配置部分
local Config = {
    -- 目标语言代码
    TargetLang = _G.TargetLang or "zh-cn", -- 通过全局变量 _G.TargetLang 设置
    
    -- API配置
    CurrentAPI = _G.CurrentAPI or "deepseek", -- 通过全局变量 _G.CurrentAPI 设置
    
    -- DeepSeek API配置
    DeepSeek = {
        APIKey = _G.DeepSeek_APIKey or "", -- 通过全局变量 _G.DeepSeek_APIKey 设置
        BaseURL = "https://api.deepseek.com/v1",
        Model = _G.DeepSeek_Model or "deepseek-chat" -- 通过全局变量 _G.DeepSeek_Model 设置
    },
    
    -- OpenAI API配置
    OpenAI = {
        APIKey = _G.OpenAI_APIKey or "", -- 通过全局变量 _G.OpenAI_APIKey 设置
        BaseURL = "https://api.openai.com/v1",
        Model = _G.OpenAI_Model or "gpt-3.5-turbo" -- 通过全局变量 _G.OpenAI_Model 设置
    },
    
    -- Claude API配置
    Claude = {
        APIKey = _G.Claude_APIKey or "", -- 通过全局变量 _G.Claude_APIKey 设置
        BaseURL = "https://api.anthropic.com/v1",
        Model = _G.Claude_Model or "claude-3-haiku-20240307" -- 通过全局变量 _G.Claude_Model 设置
    },
    
    -- Gemini API配置
    Gemini = {
        APIKey = _G.Gemini_APIKey or "", -- 通过全局变量 _G.Gemini_APIKey 设置
        BaseURL = "https://generativelanguage.googleapis.com/v1beta",
        Model = _G.Gemini_Model or "gemini-pro" -- 通过全局变量 _G.Gemini_Model 设置
    }
}

local request = request or syn.request
local HttpService = game:GetService("HttpService")

-- 输出函数
local function outputHook(fnc)
    return function(...)
        return fnc('[AI TRANSLATOR]', ...)
    end
end

local print, warn = outputHook(print), outputHook(warn)

-- JSON编码解码
function jsonEncode(o)
    return HttpService:JSONEncode(o)
end

function jsonDecode(o)
    return HttpService:JSONDecode(o)
end

-- API调用函数
local function callAPI(apiType, text, fromLang, toLang)
    local apiConfig = Config[apiType:sub(1,1):upper() .. apiType:sub(2):lower()]
    
    if not apiConfig or not apiConfig.APIKey or apiConfig.APIKey == "" then
        warn("API密钥未配置: " .. apiType)
        return nil
    end
    
    local prompt = string.format(
        "请将以下文本从%s翻译为%s，只返回翻译结果，不要添加任何解释：\n\n%s",
        fromLang == "auto" and "自动检测的语言" or fromLang,
        toLang,
        text
    )
    
    local success, result = pcall(function()
        if apiType == "deepseek" then
            return callDeepSeekAPI(apiConfig, prompt)
        elseif apiType == "openai" then
            return callOpenAIAPI(apiConfig, prompt)
        elseif apiType == "claude" then
            return callClaudeAPI(apiConfig, prompt)
        elseif apiType == "gemini" then
            return callGeminiAPI(apiConfig, prompt)
        else
            error("不支持的API类型: " .. apiType)
        end
    end)
    
    if success then
        return result
    else
        warn("API调用失败: " .. tostring(result))
        return nil
    end
end

-- DeepSeek API调用
function callDeepSeekAPI(config, prompt)
    local requestBody = jsonEncode({
        model = config.Model,
        messages = {
            {
                role = "user",
                content = prompt
            }
        },
        temperature = 0.3,
        max_tokens = 1000
    })
    
    local response = request({
        Url = config.BaseURL .. "/chat/completions",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. config.APIKey
        },
        Body = requestBody
    })
    
    if response.StatusCode == 200 then
        local data = jsonDecode(response.Body)
        return data.choices[1].message.content
    else
        error("HTTP " .. response.StatusCode .. ": " .. response.Body)
    end
end

-- OpenAI API调用
function callOpenAIAPI(config, prompt)
    local requestBody = jsonEncode({
        model = config.Model,
        messages = {
            {
                role = "user",
                content = prompt
            }
        },
        temperature = 0.3,
        max_tokens = 1000
    })
    
    local response = request({
        Url = config.BaseURL .. "/chat/completions",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. config.APIKey
        },
        Body = requestBody
    })
    
    if response.StatusCode == 200 then
        local data = jsonDecode(response.Body)
        return data.choices[1].message.content
    else
        error("HTTP " .. response.StatusCode .. ": " .. response.Body)
    end
end

-- Claude API调用
function callClaudeAPI(config, prompt)
    local requestBody = jsonEncode({
        model = config.Model,
        max_tokens = 1000,
        messages = {
            {
                role = "user",
                content = prompt
            }
        }
    })
    
    local response = request({
        Url = config.BaseURL .. "/messages",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["x-api-key"] = config.APIKey,
            ["anthropic-version"] = "2023-06-01"
        },
        Body = requestBody
    })
    
    if response.StatusCode == 200 then
        local data = jsonDecode(response.Body)
        return data.content[1].text
    else
        error("HTTP " .. response.StatusCode .. ": " .. response.Body)
    end
end

-- Gemini API调用
function callGeminiAPI(config, prompt)
    local requestBody = jsonEncode({
        contents = {
            {
                parts = {
                    {
                        text = prompt
                    }
                }
            }
        },
        generationConfig = {
            temperature = 0.3,
            maxOutputTokens = 1000
        }
    })
    
    local response = request({
        Url = config.BaseURL .. "/models/" .. config.Model .. ":generateContent?key=" .. config.APIKey,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = requestBody
    })
    
    if response.StatusCode == 200 then
        local data = jsonDecode(response.Body)
        return data.candidates[1].content.parts[1].text
    else
        error("HTTP " .. response.StatusCode .. ": " .. response.Body)
    end
end

-- 翻译函数
function translate(text, toLang, fromLang)
    fromLang = fromLang or "auto"
    toLang = toLang or Config.TargetLang
    
    local translation = callAPI(Config.CurrentAPI, text, fromLang, toLang)
    
    if translation then
        return {
            text = translation:gsub("^%s+", ""):gsub("%s+$", ""), -- 去除首尾空格
            from = {
                language = fromLang,
                text = text
            },
            raw = translation
        }
    else
        return nil
    end
end

-- 语言代码映射
local languageCodes = {
    ["zh-cn"] = "简体中文",
    ["zh-tw"] = "繁体中文",
    ["en"] = "英语",
    ["ja"] = "日语",
    ["ko"] = "韩语",
    ["es"] = "西班牙语",
    ["fr"] = "法语",
    ["de"] = "德语",
    ["it"] = "意大利语",
    ["pt"] = "葡萄牙语",
    ["ru"] = "俄语",
    ["ar"] = "阿拉伯语",
    ["hi"] = "印地语",
    ["th"] = "泰语",
    ["vi"] = "越南语",
    ["auto"] = "自动检测"
}

-- 聊天功能
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local StarterGui = game:GetService('StarterGui')

-- 等待聊天系统加载
for i=1, 15 do
    local r = pcall(StarterGui["SetCore"])
    if r then break end
    game:GetService('RunService').RenderStepped:wait()
end
wait()

local properties = {
    Color = Color3.new(1,1,0);
    Font = Enum.Font.SourceSansItalic;
    TextSize = 16;
    Text = "";
}

-- 通知用户
game:GetService("StarterGui"):SetCore("SendNotification",
    {
        Title = "AI聊天翻译器",
        Text = "当前API: " .. Config.CurrentAPI:upper(),
        Duration = 3
    }
)

properties.Text = "使用方法:\n>语言代码 - 设置翻译目标语言\n>api API名称 - 切换API (deepseek/openai/claude/gemini)\n>d - 禁用翻译发送\n例如: >zh-cn 或 >api openai"
StarterGui:SetCore("ChatMakeSystemMessage", properties)

-- 翻译接收到的消息
function translateFrom(message)
    local translation = translate(message, Config.TargetLang)
    
    if translation then
        return {translation.text, translation.from.language}
    else
        return nil
    end
end

-- 检测聊天系统版本并获取相应组件
local TextChatService = game:GetService("TextChatService")
local isNewChatSystem = TextChatService.ChatVersion == Enum.ChatVersion.TextChatService

local CBar, Connected

if isNewChatSystem then
    -- 新版本聊天系统
    local chatInputConfiguration = TextChatService:WaitForChild("ChatInputConfiguration", 10)
    if chatInputConfiguration then
        -- 新版本使用不同的方法获取输入框
        warn("使用新版本TextChatService")
        -- 新版本需要通过不同的方式处理聊天输入
    else
        warn("无法找到新版本聊天配置")
        return
    end
else
    -- 旧版本聊天系统
    local ChatGui = LP['PlayerGui']:WaitForChild('Chat', 30)
    if not ChatGui then
        warn("无法找到聊天界面，请确保聊天系统已启用")
        return
    end
    CBar = ChatGui['Frame'].ChatBarParentFrame['Frame'].BoxFrame['Frame'].ChatBar
    Connected = {}
end
local EventFolder = game:GetService('ReplicatedStorage'):WaitForChild('DefaultChatSystemChatEvents')

local function Chat(Original, msg, Channel)
    CBar.Text = msg
    for i,v in pairs(getconnections(CBar.FocusLost)) do
        v:Fire(true, nil, true)
    end
end

-- 处理接收到的消息
do
    function get(plr, msg)
        local tab = translateFrom(msg)
        if tab then
            properties.Text = "("..tab[2]:upper()..") ".."[".. plr .."]: "..tab[1]
            StarterGui:SetCore("ChatMakeSystemMessage", properties)
        end
    end

    EventFolder:WaitForChild("OnMessageDoneFiltering").OnClientEvent:Connect(function(data)
        if data == nil then return end

        local plr = Players:FindFirstChild(data.FromSpeaker)
        local msg = tostring(data.Message)
        local originalchannel = tostring(data.OriginalChannel)

        if plr then 
            plr = plr.DisplayName 
        else 
            plr = tostring(data.FromSpeaker)
        end

        if originalchannel:find("To ") then
            plr = plr..originalchannel
        end

        get(plr, msg)
    end)
end

-- 发送翻译功能
local sendEnabled = false
local target = ""

function translateTo(message, target)
    target = target:lower() 
    local translation = translate(message, target, "auto")
    
    if translation then
        return translation.text
    else
        return message
    end
end

function disableSend()
    sendEnabled = false
    properties.Text = "[AI翻译] 发送翻译已禁用"
    StarterGui:SetCore("ChatMakeSystemMessage", properties)
end

-- 聊天栏钩子
local HookChat = function(Bar)
    coroutine.wrap(function()
        if not table.find(Connected,Bar) then
            local Connect = Bar['FocusLost']:Connect(function(Enter, _, ignore)
                if ignore then return end
                if Enter ~= false and Bar.Text ~= '' then
                    local Message = Bar.Text
                    Bar.Text = ''
                    
                    -- 处理命令
                    if Message == ">d" then
                        disableSend()
                    elseif Message:sub(1,1) == ">" and not Message:find(" ") then
                        local command = Message:sub(2):lower()
                        
                        -- API切换命令
                        if command:sub(1,3) == "api" then
                            local apiName = command:sub(5)
                            if apiName == "deepseek" or apiName == "openai" or apiName == "claude" or apiName == "gemini" then
                                Config.CurrentAPI = apiName
                                properties.Text = "[AI翻译] 已切换到 " .. apiName:upper() .. " API"
                                StarterGui:SetCore("ChatMakeSystemMessage", properties)
                            else
                                properties.Text = "[AI翻译] 不支持的API: " .. apiName
                                StarterGui:SetCore("ChatMakeSystemMessage", properties)
                            end
                        -- 语言设置命令
                        elseif languageCodes[command] then
                            sendEnabled = true
                            target = command
                            properties.Text = "[AI翻译] 目标语言设置为: " .. languageCodes[command]
                            StarterGui:SetCore("ChatMakeSystemMessage", properties)
                        else
                            properties.Text = "[AI翻译] 无效的语言代码或命令"
                            StarterGui:SetCore("ChatMakeSystemMessage", properties)
                        end
                    elseif sendEnabled and not (Message:sub(1,3) == "/e " or Message:sub(1,7) == "/emote ") then
                        local og = Message
                        Message = translateTo(Message, target)
                        Chat(og, Message)
                    else
                        Chat(Message, Message)
                    end
                end
            end)
            Connected[#Connected+1] = Bar; Bar['AncestryChanged']:Wait(); Connect:Disconnect()
        end
    end)()
end

HookChat(CBar)
local BindHook = Instance.new('BindableEvent')

local MT = getrawmetatable(game)
local NC = MT.__namecall
setreadonly(MT, false)

MT.__namecall = newcclosure(function(...)
    local Method, Args = getnamecallmethod(), {...}
    if rawequal(tostring(Args[1]),'ChatBarFocusChanged') and rawequal(Args[2],true) then 
        if LP['PlayerGui']:FindFirstChild('Chat') then
            BindHook:Fire()
        end
    end
    return NC(...)
end)

BindHook['Event']:Connect(function()
    local ChatGui = LP['PlayerGui']:FindFirstChild('Chat')
    if ChatGui then
        CBar = ChatGui['Frame'].ChatBarParentFrame['Frame'].BoxFrame['Frame'].ChatBar
        HookChat(CBar)
    end
end)
