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
    print("调用API:", apiType)
    
    local apiConfig = Config[apiType:sub(1,1):upper() .. apiType:sub(2):lower()]
    
    if not apiConfig then
        warn("API配置不存在: " .. apiType)
        return nil
    end
    
    if not apiConfig.APIKey or apiConfig.APIKey == "" then
        warn("API密钥未配置: " .. apiType)
        print("请设置 _G." .. apiType:sub(1,1):upper() .. apiType:sub(2):lower() .. "_APIKey")
        return nil
    end
    
    local prompt = string.format(
        "请将以下文本从%s翻译为%s，只返回翻译结果，不要添加任何解释：\n\n%s",
        fromLang == "auto" and "自动检测的语言" or fromLang,
        toLang,
        text
    )
    
    print("提示词:", prompt)
    
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
        print("API调用成功，结果:", result)
        return result
    else
        warn("API调用失败: " .. tostring(result))
        print("错误详情:", debug.traceback())
        return nil
    end
end

-- DeepSeek API调用
function callDeepSeekAPI(config, prompt)
    print("调用DeepSeek API")
    
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
    
    print("请求URL:", config.BaseURL .. "/chat/completions")
    print("请求体:", requestBody)
    
    local success, response = pcall(function()
        return request({
            Url = config.BaseURL .. "/chat/completions",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = "Bearer " .. config.APIKey
            },
            Body = requestBody
        })
    end)
    
    if not success then
        error("DeepSeek请求失败: " .. tostring(response))
    end
    
    print("响应状态码:", response.StatusCode)
    print("响应内容:", response.Body)
    
    if response.StatusCode == 200 then
        local success, data = pcall(function()
            return jsonDecode(response.Body)
        end)
        
        if not success then
            error("DeepSeek JSON解析失败: " .. tostring(data))
        end
        
        if data.choices and data.choices[1] and data.choices[1].message and data.choices[1].message.content then
            return data.choices[1].message.content
        else
            error("DeepSeek响应格式错误: " .. response.Body)
        end
    else
        error("DeepSeek HTTP错误 " .. response.StatusCode .. ": " .. response.Body)
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
    print("开始翻译，使用API:", Config.CurrentAPI)
    print("原文:", text)
    print("目标语言:", toLang or Config.TargetLang)
    print("源语言:", fromLang or "auto")
    
    fromLang = fromLang or "auto"
    toLang = toLang or Config.TargetLang
    
    -- 检查API配置
    local apiConfig = Config[Config.CurrentAPI:sub(1,1):upper() .. Config.CurrentAPI:sub(2):lower()]
    if not apiConfig then
        warn("API配置不存在:", Config.CurrentAPI)
        return nil
    end
    
    if not apiConfig.APIKey or apiConfig.APIKey == "" then
        warn("API密钥未配置:", Config.CurrentAPI)
        return nil
    end
    
    local translation = callAPI(Config.CurrentAPI, text, fromLang, toLang)
    
    if translation then
        print("翻译成功:", translation)
        return {
            text = translation:gsub("^%s+", ""):gsub("%s+$", ""), -- 去除首尾空格
            from = {
                language = fromLang,
                text = text
            },
            raw = translation
        }
    else
        warn("翻译失败，返回nil")
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

-- 初始化检查和测试函数
local function testConfiguration()
    print("=== 配置检查 ===")
    print("当前API:", Config.CurrentAPI)
    
    local apiConfig = Config[Config.CurrentAPI:sub(1,1):upper() .. Config.CurrentAPI:sub(2):lower()]
    if apiConfig then
        print("API配置存在")
        print("API密钥状态:", apiConfig.APIKey and "已设置" or "未设置")
        print("BaseURL:", apiConfig.BaseURL)
        print("Model:", apiConfig.Model)
    else
        warn("API配置不存在")
    end
    
    -- 测试StarterGui
    local success, err = pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", properties)
    end)
    
    if success then
        print("StarterGui测试成功")
    else
        warn("StarterGui测试失败:", err)
    end
    
    print("=== 配置检查完成 ===")
end

-- 通知用户
game:GetService("StarterGui"):SetCore("SendNotification",
    {
        Title = "AI聊天翻译器",
        Text = "当前API: " .. Config.CurrentAPI:upper(),
        Duration = 3
    }
)

properties.Text = "使用方法:\n>语言代码 - 设置翻译目标语言\n>api API名称 - 切换API (deepseek/openai/claude/gemini)\n>d - 禁用翻译发送\n>test - 测试配置\n例如: >zh-cn 或 >api openai"
StarterGui:SetCore("ChatMakeSystemMessage", properties)

-- 运行配置检查
testConfiguration()

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
        print("开始翻译消息:", msg)
        print("发送者:", plr)
        
        local tab = translateFrom(msg)
        if tab then
            local translatedText = "("..tab[2]:upper()..") ".."[".. plr .."]: "..tab[1]
            print("翻译结果:", translatedText)
            
            properties.Text = translatedText
            print("设置properties.Text为:", properties.Text)
            
            local success, err = pcall(function()
                StarterGui:SetCore("ChatMakeSystemMessage", properties)
            end)
            
            if success then
                print("成功发送系统消息")
            else
                warn("发送系统消息失败:", err)
            end
        else
            warn("翻译失败，返回nil")
        end
    end

    EventFolder:WaitForChild("OnMessageDoneFiltering").OnClientEvent:Connect(function(data)
        print("收到聊天事件")
        if data == nil then 
            warn("聊天数据为空")
            return 
        end

        print("聊天数据:", data)
        
        local plr = Players:FindFirstChild(data.FromSpeaker)
        local msg = tostring(data.Message)
        local originalchannel = tostring(data.OriginalChannel)

        print("提取的消息内容:", msg)
        print("原始频道:", originalchannel)

        if plr then 
            plr = plr.DisplayName 
            print("找到玩家，显示名称:", plr)
        else 
            plr = tostring(data.FromSpeaker)
            print("未找到玩家，使用原始名称:", plr)
        end

        if originalchannel:find("To ") then
            plr = plr..originalchannel
            print("私聊消息，更新玩家名称:", plr)
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
                    elseif Message == ">test" then
                        testConfiguration()
                        properties.Text = "[AI翻译] 配置检查完成，查看控制台输出"
                        StarterGui:SetCore("ChatMakeSystemMessage", properties)
                    elseif Message:sub(1,1) == ">" and not Message:find(" ") then
                        local command = Message:sub(2):lower()
                        
                        -- API切换命令
                        if command:sub(1,3) == "api" then
                            local apiName = command:sub(5)
                            if apiName == "deepseek" or apiName == "openai" or apiName == "claude" or apiName == "gemini" then
                                Config.CurrentAPI = apiName
                                properties.Text = "[AI翻译] 已切换到 " .. apiName:upper() .. " API"
                                StarterGui:SetCore("ChatMakeSystemMessage", properties)
                                testConfiguration()
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
                            properties.Text = "[AI翻译] 无效的语言代码或命令。可用命令: >test, >d, >api [deepseek/openai/claude/gemini], >[语言代码]"
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
