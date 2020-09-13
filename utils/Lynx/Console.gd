extends CanvasLayer

#分为左右两栏，左边是控制台，处理输入的指令。右边是日志，用于记录运行过程中出现的问题。

###################################################颜色设置
const user_input_color = Color.gray
const warning_color = Color.yellow
const error_color = Color.red
const color1 = Color(255/255.0, 121/255.0, 198/255.0)
const color2 = Color(99/255.0, 220/255.0, 245/255.0)
const color3 = Color(98/255.0, 114/255.0, 164/255.0)
#########################################################

onready var input_box = $C/VBoxContainer/HBoxContainer/InputBox
onready var console = $C/VBoxContainer/HSplitContainer/VBoxContainer/ConsoleOutput
onready var logcat = $C/VBoxContainer/HSplitContainer/VBoxContainer2/Logcat


func _ready():
	#默认隐藏状态
	$C.visible = false
	#如果没有设置打开控制台的快捷键，提醒一下
	if not InputMap.has_action("toggle_console"):
		print("WARNING: You haven't set 'toggle_console' in InputMap yet. Which means you can't use Lynx In-game Console.")
	#加载默认指令模块
	load_command_module(self)

func _input(_event):
	if Input.is_action_just_pressed("toggle_console"):
		$C.visible = not $C.visible
		#调出界面时自动获取焦点
		if $C.visible: 
			input_box.grab_focus()
			#如果没有这一行，调出时会多出一个`（调出控制台的快捷键）
			get_tree().set_input_as_handled()
func _on_Button_pressed(): _send_command()
func _on_InputBox_text_entered(_n): _send_command()
func _send_command():
	write_console("[color=#%s][You]%s[/color]"%[user_input_color.to_html(false), input_box.text])
	_dispatch_command(input_box.text)
	input_box.text = ""

###########################打印日志
const _prefix = "> "
#info
func i(s:String):
	logcat.bbcode_text += _prefix + s + "\n"
#warning
func w(s:String):
	logcat.bbcode_text += _prefix + "[color=#%s]%s\n[/color]"%[warning_color.to_html(false), s]
#error
func e(s:String):
	logcat.bbcode_text += _prefix + "[color=#%s]%s\n[/color]"%[error_color.to_html(false), s]
#################################

#可以直接在脚本中输入指令并执行
func execute_command(s:String, hidden:=false):
	if not hidden:
		write_console("[color=#%s][Script] %s[/color]"%[user_input_color.to_html(false), s])
	_dispatch_command(s)

###################################
#如何处理输入的指令呢？
#首先按空格拆分指令，分解成小字符串的数组
#然后按照第一个字符串寻找对应的函数
#按照顺序到不同的对象中寻找函数
#函数名以___开头，全大写
#另外每添加一次模块，都会调用它指定的欢迎函数
##################################

#这里保存不同的指令模块，优先级从左到右
var command_modules := []
#加载指令模块，并调用它提供的帮助指令,模块之间的指令不要同名
func load_command_module(ch):
	command_modules.append(ch)
	write_console("Module loaded.")
	_call_helper()
func unload_command_module():
	command_modules.remove(-1)
func write_console(s:String, new_line := true, color:=Color.white):
	console.bbcode_text += "[color=#%s]%s[/color]"%[color.to_html(false), s]
	if new_line: console.bbcode_text += "\n"
func _call_helper(idx := -1):
	assert(command_modules.size() > 0)
	var mi = command_modules[idx].get("MODULE_INFO")
	assert(mi != null)
	write_console("[color=#%s]MODULE_NAME: %s[/color]"%[color3.to_html(false),mi.module_name])
	write_console("[color=#%s]MODULE_DESC: %s[/color]"%[color3.to_html(false),mi.module_desc])
	for c in mi.commands:
		write_console("[color=#%s]%s[/color] ([color=#%s]%s[/color])"%[color1.to_html(false), c, color2.to_html(false), mi.commands[c].desc])
	write_console("")
func _list_all_modules():
	assert(command_modules.size() > 0)
	write_console("Available Modules: ", true, color3)
	for m in command_modules:
		var mi = m.get("MODULE_INFO")
		write_console(mi.module_name, true, color3)
	
func _dispatch_command(c:String):
	#指令区分大小写
	var paras = c.split(" ", false)
	if paras.empty(): return
	var command = paras[0]
	paras.remove(0)
	for m in command_modules:
		var mi = m.get("MODULE_INFO")
		if mi.commands.has(command):
			m.call(mi.commands[command].method, paras)
			return
	write_console("[color=#ff0000]Unknown command.[/color]")
#################################
#默认的指令处理模块
#提供了一些基础的指令
const MODULE_INFO = {
	"module_name": "Welcome",
	"module_desc": "Some basic commands as examples",
	"commands": {
		"help": {
			"method": "___HELP",
			"desc": "help [module_name] - show help information"
		},
		"echo": {
			"method": "___ECHO",
			"desc": "echo [words] - simply print something"
		},
		"clear": {
			"method": "___CLEAR",
			"desc": "clear all content in console"
		}
	}
}

func ___HELP(arg_array:Array):
	if arg_array.size() > 1:
		write_console("at most 1 argument expected, given %d."%arg_array.size(), true, Color.red)
		return
	if arg_array.size() != 0:
		for i in range(command_modules.size()):
			var mi = command_modules[i].get("MODULE_INFO")
			if mi.module_name == arg_array[0]:
				_call_helper(i)
				return
		write_console("can not find %s!"%arg_array[0], true, Color.red)
		_list_all_modules()
		return
	if arg_array.size() == 0:
		_call_helper(0)
		_list_all_modules()
func ___ECHO(arg_array:Array):
	if arg_array.size() < 1:
		write_console("at least 1 argument, given 0.", true, Color.red)
		return
	for arg in arg_array:
		write_console(arg + " ", false)
	write_console("")
func ___CLEAR(arg_array:Array):
	if arg_array.size() > 0:
		write_console("at most 0 argument, given %d."%arg_array.size())
		return
	console.bbcode_text = ""
#################################

func _on_Button2_pressed():
	logcat.bbcode_text = ""
