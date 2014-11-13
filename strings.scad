_digit = "0123456789";
_lowercase = "abcdefghijklmnopqrstuvwxyz";
_uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
_letter = str(_lowercase, _uppercase);
_alphanumeric = str(_letter, _digit);
_whitespace = " \t\r\n";
_nonsymbol = str(_alphanumeric, _whitespace);

test = "foo  (1, bar2)";
regex_test = "foooobazfoobarbaz";
_regex_ops = "\\?*+&|";







function grep(string, pattern, index=0) = 		//string
	_between_range(string, _find_regex(string, pattern, index));





function replace(string, replaced, replacement, ignore_case=ignore_case, regex=false) = 	//string
	regex?
		_replace_regex(string, replaced, replacement)
	: string == undef?
		undef
	: pos >= len(string)?
		""
	: contains(string, replaced)?
		str(	before(string, find(string, replaced, ignore_case=ignore_case)),
			replacement,
			replace(after(string, find(string, replaced, ignore_case=ignore_case)+len(replaced)-1), 
				replaced, replacement, ignore_case=ignore_case)
		)
	: 
		string
	;
function _replace_regex(string, pattern, replacement) = 	//string
	string == undef?
		undef
	: pos >= len(string)?
		""
	:
		_replace_between_range(string, pattern, replacement, _find_regex(string, pattern))
	;
function _replace_between_range(string, pattern, replacement, range) = 
	range == undef?
		str(	before(string, range.x),
			replacement,
			_replace_regex(after(string, range.y-1), 
				pattern, replacement)
		)
	: 
		string
	;




function split(string, seperator=" ", index=0, ignore_case = false) = 
	!contains(string, seperator, ignore_case=ignore_case) ?
		string
	: index < 0?
		undef
	: index == 0?
		between(string, 0, find(string, seperator, index))
	:
		between(string, _null_coalesce(find(string, seperator, index-1)+len(seperator), len(string)+1), 
				_null_coalesce(find(string, seperator, index), 		 len(string)+1)) 
	;
//function _split_regex(string, pattern, index) =		//string	
//	index <= 0?
//		before(string, 0, _find_regex(string, pattern, index).x)
//	:
//		between(string, 
//			_find_regex(string, pattern, index).y, 
//			_find_regex(string, pattern, index+1).x);




function contains(string, substring, ignore_case=false, regex=false) = 
	regex?
		_contains_regex(string, substring)
	:
		find(string, substring, ignore_case=ignore_case) != undef
	; 
function _contains_regex(string, pattern) = 			//bool		
	_find_regex(string, pattern) != undef;
	



function find(string, goal, index=0, pos=0, ignore_case=false, regex=false) = 
	regex?
		_find_regex(string, goal)
	: len(goal) == 1 && !ignore_case?
		search(goal, after(string, pos), 0)[0][index] + pos + 1
	: index <= 0?
		_find_first(string, goal, pos, ignore_case=ignore_case)
	: 
		find(string, goal, index-1, 
			pos = _find_first(string, goal, ignore_case=ignore_case) + len(goal),
			ignore_case=ignore_case)
	;

function _find_first(string, goal, pos=0, ignore_case=false, regex=false) = 
	string == undef?
		undef
	: goal == undef?
		undef
	: pos < 0 || pos == undef?
		undef
	: pos >= len(string)?
		undef
	: starts_with(string, goal, pos, ignore_case)?
		pos
	:
		_find_first(string, goal, pos+1, ignore_case)
	;
function _find_regex(string, pattern, index=0, pos=0) = 		//[start,end]
	index == 0?
		_find_first_regex(string, pattern, pos)
	:
		_find_regex(string, pattern, 
			index = index-1,
			pos = _find_first_regex(string, pattern, pos).y + 1)
	;
function _find_first_regex(string, pattern, pos=0) =
	pos >= len(string)?
		undef
	: _coalesce_on([pos, _match_regex(string, pattern, pos)], 
		[pos, undef],
		_find_first_regex(string, pattern, pos+1));





function starts_with(string, start, index=0, ignore_case=false) = 
	equals(	substring(string, index, len(start)), 
		start, 
		ignore_case=ignore_case);
function ends_with(string, end, ignore_case=false) =
	equals(	after(string, len(string)-len(end)-1), 
		end,
		ignore_case=ignore_case)
	;



function equals(this, that, ignore_case=false) =
	ignore_case?
		lower(this) == lower(that)
	:
		this==that
	;





function _match_regex(string, pattern, pos=0) = 		//end pos
	_match_prefix_regex(string,
		_compile_regex(pattern), pos, 0);

function _compile_regex(regex) = 
	_infix_to_prefix(
		_explicitize_regex_concatenation(
			_explicitize_regex_alternation(regex)), 
		_regex_ops);

function _explicitize_regex_alternation(regex, stack="", i=0) = 
	i >= len(regex)?
		""
	//: i+1 >= len(regex)?
	//	regex[i]
	: stack[0] == "["?
		regex[i] == "]"?
			str(")", 		_explicitize_regex_alternation(regex, stack=_pop(stack),		i=i+1))
		:
			str("|", regex[i], 	_explicitize_regex_alternation(regex, stack=stack,			i=i+1))
	: regex[i] == "["?
			str("(", regex[i+1],	_explicitize_regex_alternation(regex, stack=_push(stack, regex[i]), i=i+2))
	:		
			str(regex[i], 	_explicitize_regex_alternation(regex, stack=stack,				i=i+1))
	;
function _explicitize_regex_concatenation(regex, stack="", i=0) = 
	i >= len(regex)?
		""
	: i+1 >= len(regex)?
		regex[i]
	: !_is_in(regex[i], "\\|()") && !_is_in(regex[i+1], "*+?|)")?
		str(regex[i], "&", 	_explicitize_regex_concatenation(regex, stack, i+1))
	: 
		str(regex[i], 		_explicitize_regex_concatenation(regex, stack, i+1))
	;
//converts infix to postfix using shunting yard algorithm
function _infix_to_postfix(infix, ops, stack="", i=0) = 
	infix == undef?
		undef
	: ops == undef?
		undef
	: i == undef?
		undef
	: i >= len(infix)?
		stack
	: _is_in(infix[i], ops)?
		stack[0] == "(" || len(stack) <= 0 || _precedence(infix[i], ops) < _precedence(stack[0], ops)?
			str(		_infix_to_postfix(infix, ops, stack=_push(stack, infix[i]), 	i=i+1))
		:
			str(stack[0], 	_infix_to_postfix(infix, ops, stack=_pop(stack),		i=i))
	: infix[i] == "("?
			str(		_infix_to_postfix(infix, ops, stack=_push(stack, infix[i]), 	i=i+1))
	: infix[i] == ")"?
		stack[0] == "(" ?
			str(		_infix_to_postfix(infix, ops, stack=_pop(stack),		i=i+1))
		: len(stack) <= 0 ?
			str(		_infix_to_postfix(infix, ops, stack=stack,			i=i+1))
		: 
			str(stack[0], 	_infix_to_postfix(infix, ops, stack=_pop(stack),		i=i))
	:
			str(infix[i], 	_infix_to_postfix(infix, ops, stack=stack, 			i=i+1))
	;

//converts infix to prefix using shunting yard algorithm
function _infix_to_prefix(infix, ops, stack="", i=undef) = 
	infix == undef?
		undef
	: ops == undef?
		undef
	: i == undef?
		_infix_to_prefix(infix, ops, stack, i=len(infix)-1)
	: i < 0?
		reverse(stack)
	: _is_in(infix[i], ops)?
		stack[0] == ")" || len(stack) <= 0 || _precedence(infix[i], ops) < _precedence(stack[0], ops)?
			str(_infix_to_prefix(infix, ops, stack=str(infix[i], stack), 	i=i-1))
		:
			str(_infix_to_prefix(infix, ops, stack=after(stack, 0), 			i=i), stack[0])
	: infix[i] == ")"?
			str(_infix_to_prefix(infix, ops, stack=str(infix[i], stack), 	i=i-1))
	: infix[i] == "("?
		stack[0] == ")" ?
			str(_infix_to_prefix(infix, ops, stack=after(stack, 0),			i=i-1))
		: len(stack) <= 0 ?
			str(_infix_to_prefix(infix, ops, stack=stack,				i=i-1))
		: 
			str(_infix_to_prefix(infix, ops, stack=after(stack, 0),		 	i=i), stack[0])
	:
			str(_infix_to_prefix(infix, ops, stack=stack, 				i=i-1), infix[i])
	;

function _pop(stack) = 
	after(stack, 0);
function _push(stack, char) = 
	str(char, stack);

function _precedence(op, ops) = 
	search(op, ops)[0];
		
function _match_prefix_regex(string, regex, string_pos, regex_pos=0)=
	//INVALID INPUT
	string == undef?
		undef
	: regex == undef?
		undef
		
	//regex length
	: regex_pos == undef?
		undef
	: regex_pos >= len(regex)?
		undef
		
	
	//string length and anchors
	: regex[regex_pos] == "^"?
		string_pos == 0?
			string_pos
		:
			undef
	: regex[regex_pos] == "$"?
		string_pos >= len(string)?
			string_pos
		:
			undef
	: string_pos == undef?
		undef
	: string_pos >= len(string)?
		undef

	//ALTERNATION
	: regex[regex_pos] == "|" ?
		_null_coalesce(_match_prefix_regex(string, regex, string_pos, regex_pos+1),
				_match_prefix_regex(string, regex, string_pos, 
					_match_prefix(regex, "\\*+?", "|&", regex_pos+1)))

	//KLEENE STAR
	: regex[regex_pos] == "*" ?
		_null_coalesce(
			_match_prefix_regex(string, regex,
				_match_prefix_regex(string, regex, string_pos, regex_pos+1),
				regex_pos),
			string_pos)

	//KLEENE PLUS
	: regex[regex_pos] == "+" ?
		_null_coalesce(
			_match_prefix_regex(string, regex,
				_match_prefix_regex(string, regex, string_pos, regex_pos+1),
				regex_pos),
			_match_prefix_regex(string, regex, string_pos, regex_pos+1))

	//OPTION
	: regex[regex_pos] == "?" ?
		_null_coalesce(_match_prefix_regex(string, regex, string_pos, regex_pos+1),
				string_pos)

	//CONCATENATION
	: regex[regex_pos] == "&" ?	
		_match_prefix_regex(string, regex, 
			_match_prefix_regex(string, regex, string_pos, regex_pos+1), 
			_match_prefix(regex, "\\*+?", "|&", regex_pos+1))
			
	//ESCAPE CHARACTER
	: regex[regex_pos] == "\\"?
		regex[regex_pos+1] == "d"?
			_is_in(string[string_pos], _digit)?
				string_pos+1
			: 
				undef
		: regex[regex_pos+1] == "s"?
			_is_in(string[string_pos], _whitespace)?
				string_pos+1
			: 
				undef
		: regex[regex_pos+1] == "w"?
			_is_in(string[string_pos], _alphanumeric)?
				string_pos+1
			: 
				undef
		: regex[regex_pos+1] == "D"?
			!_is_in(string[string_pos], _digit)?
				string_pos+1
			: 
				undef
				
		: regex[regex_pos+1] == "S"?
			!_is_in(string[string_pos], _whitespace)?
				string_pos+1
			: 
				undef
		: regex[regex_pos+1] == "W"?
			!_is_in(string[string_pos], _alphanumeric)?
				string_pos+1
			: 
				undef
		:
			string[string_pos] == regex[regex_pos+1]?
				string_pos+1
			:
				undef

	//LITERAL
	: string[string_pos] == regex[regex_pos] ?
		string_pos+1

	//WILDCARD
	: regex[regex_pos] == "."?
		string_pos+1

	//NO MATCH
	: 
		undef
	;
	
function _match_prefix(regex, unary, binary, pos=0) = 
	pos >= len(regex)?
		len(regex)
	: _is_in(regex[pos], unary)?
		_match_prefix(regex, unary, binary, pos+1)
	: _is_in(regex[pos], binary)?
		_match_prefix(regex, unary, binary,  _match_prefix(regex, unary, binary, pos+1))
	: 
		pos+1
	;

function token(string, index, pos=0) = 
	index == 0?
		_coalesce_on(between(string, _token_start(string, pos), _token_end(string, pos)),
				"",
				undef)
	:
		token(string, index-1, _token_end(string, pos))
	;

function _token_start(string, pos=0, ignore_space=true) = 
	pos >= len(string)?
		undef
	: pos == len(string)?
		len(string)
	: _is_in(string[pos], _whitespace) && ignore_space?
		_match_set(string, _whitespace, pos)
	: //symbol
		pos
	;
	

function _token_end(string, pos=0, ignore_space=true, tokenize_quotes=true) = 
	pos >= len(string)?
		len(string)
	: _is_in(string[pos], _alphanumeric) ?
		_match_set(string, _alphanumeric, pos)
	: _is_in(string[pos], _whitespace) ? (
		ignore_space?
			_token_end(string, _match_set(string, _whitespace, pos))
		:
			_match_set(string, _whitespace, pos)
	)
	
	: string[pos] == "\"" && tokenize_quotes ?
		_match_quote(string, "\"", pos+1)
	: string[pos] == "'" && tokenize_quotes?
		_match_quote(string, "'", pos+1)
	: 
		pos+1
	;

function is_empty(string) = 
	string == "";

function is_null_or_empty(string) = 
	string == undef || string == "";
	
function is_null_or_whitespace(string) = 
	string == undef || trim(string) == "";

function trim(string) = 
	string == undef?
		undef
	: string == ""?
		""
	:
		_null_coalesce(
			between(string, _match_set(string, _whitespace, 0), 
					_match_set_reverse(string, _whitespace, len(string))),
			""
		)
	;

function _match_set(string, set, pos) = 
	pos >= len(string)?
		len(string)
	: _is_in(string[pos], set )?
		_match_set(string, set, pos+1)
	: 
		pos
	;

function _match_set_reverse(string, set, pos) = 
	pos <= 0?
		0
	: _is_in(string[pos-1], set)?
		_match_set_reverse(string, set, pos-1)
	: 
		pos
	;

function _match_quote(string, quote_char, pos) = 
	pos >= len(string)?
		len(string)
	: string[pos] == quote_char?
		pos
	: string[pos] == "\\"? 
		_match_quote(string, quote_char, pos+2)
	: 
		_match_quote(string, quote_char, pos+1)
	;


// quicker in theory, but slow in practice due to generated warnings
//function _is_in(string, set, index=0) = 
//	len(search(string[index],set)) > 0;
function _is_in(char, string, index=0) = 
	index >= len(string)?
		false
	: char == string[index]?
		true
	:
		_is_in(char, string, index+1)
	;

function lower(string) = 
	_transform_case(string, search(string, "ABCDEFGHIJKLMNOPQRSTUVWXYZ",0), 97);

function upper(string) = 
	_transform_case(string, search(string, "abcdefghijklmnopqrstuvwxyz",0), 65);

function _transform_case(string, encoded, offset, index=0) = 
	index >= len(string)?
		""
	: len(encoded[index]) <= 0?
		str(substring(string, index, 1),	_transform_case(string, encoded, offset, index+1))
	: 
		str(chr(encoded[index][0]+offset),	_transform_case(string, encoded, offset, index+1))
	;



function join(strings, delimeter) = 
	strings == undef?
		undef
	: strings == []?
		""
	: _join(strings, len(strings)-1, delimeter, 0);

function _join(strings, index, delimeter) = 
	index==0 ? 
		strings[index] 
	: str(_join(strings, index-1, delimeter), delimeter, strings[index]) ;
	
function reverse(string, i=0) = 
	string == undef?
		undef
	: len(string) <= 0?
		""
	: i <= len(string)-1?
		str(reverse(string, i+1), string[i])
	:
		"";

function substring(string, start, length=undef) = 
	length == undef? 
		between(string, start, len(string)) 
	: 
		between(string, start, length+start)
	;

function _between_range(string, vector) = 
	vector == undef?
		undef
	: 
		between(string, vector.x, vector.y)
	;
//note: start is inclusive, end is exclusive
function between(string, start, end) = 
	string == undef?
		undef
	: start == undef?
		undef
	: start > len(string)?
		undef
	: start < 0?
		before(string, end)
	: end == undef?
		undef
	: end <= 0?
		undef
	: end > len(string)?
		after(string, start-1)
	: start > end?
		undef
	: start == end ? 
		"" 
	: 
		str(string[start], between(string, start+1, end))
	;

function before(string, index=0) = 
	string == undef?
		undef
	: index == undef?
		undef
	: index > len(string)?
		string
	: index <= 0?
		""
	: 
		str(before(string, index-1), string[index-1])
	;

function after(string, index=0) =
	string == undef?
		undef
	: index == undef?
		undef
	: index < 0?
		string
	: index >= len(string)-1?
		""
	:
		str(string[index+1], after(string, index+1))
	;
	
function parse_int(string, base=10, i=0, nb=0) = 
	string[0] == "-" ? 
		-1*_parse_int(string, base, 1) 
	: 
		_strToInt(str, base);

function _parse_int(string, base, i=0, nb=0) = 
	i == len(string) ? 
		nb 
	: 
		nb + _parse_int(string, base, i+1, 
				search(string[i],"0123456789ABCDEF")[0]*pow(base,len(string)-i-1));


function _null_coalesce(string, replacement) = 
	string == undef?
		replacement
	:
		string
	;
function _coalesce_on(value, error, fallback) = 
	value == error?
		fallback
	: 
		value
	;
	

