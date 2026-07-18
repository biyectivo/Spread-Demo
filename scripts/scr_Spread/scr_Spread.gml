///@feather ignore all


#macro		SPREAD_VERSION							"0.1"
#macro		SPREAD_LOG_PREFIX						string($"[Spread v{SPREAD_VERSION}]:")			
#macro		SPREAD_REGEX_SPACE_ESCAPE_CHAR			"¬"
#macro		SPREAD_REGEX_PROCESSING_CHAR			"«"
#macro		SPREAD_REGEX_DEFAULT_FLAGS				"s"

#region Init

	global.Spread = {};

	global.Spread.connections = {};
	global.Spread.tables = {};
	global.Spread.table_metadata = {};
		
#endregion

#region Enums 

	enum SPREAD_MESSAGE_LEVEL {
		INFO,
		WARNING,
		ERROR,
		SYSTEM
	}
	
#endregion

#region String version of enums

	global.Spread.enums = {};
	global.Spread.enums[$ "SPREAD_MODE"] = ["DEV", "PROD"];
	global.Spread.enums[$ "MESSAGE_LEVEL"] = ["INFO", "WARNING", "ERROR", "SYSTEM"];

#endregion

#region Validation Schemas

	function Spread_Schema() constructor {
	}
	
	/**
	 * @desc	constructor for a numeric schema for Spread fields
	 * @param	{string}		_name 						the field name
	 * @param	{bool}			_required					whether it's required or not
	 * @param	{bool}			[_is_integer]=false			whether it's an integer or accepts floating point values
	 * @param	{real}			[_min]=-infinity			minimum value
	 * @param	{real}			[_max]=infinity				maximum value
	 * @param	{bool}			[_exclusive_min]=false		whether the minimum value cannot be a valid value (i.e. > instead of >= comparison)
	 * @param	{bool}			[_exclusive_max]=false		whether the maximum value cannot be a valid value (i.e. < instead of <= comparison)
	 * @param	{array}			[_allowed_list]=[]			an array with an allowed list of numbers, useful for catalogs/categorical data/enums
	 * @param	{array}			[_forbidden_list]=[]		an array with a forbidden list of numbers, useful for catalogs/categorical data/enums
	 * @param	{bool}			[_treat_as_dates]=false		whether to treat the number as a numeric date XLSX (this means the value will be imported as YYYY-MM-DD in the actual table)
	 */
	function Spread_Num(_name, _required, _is_integer=false, _min=-infinity, _max=infinity, _exclusive_min=false, _exclusive_max=false, _allowed_list=[], _forbidden_list=[], _treat_as_dates=false) : Spread_Schema() constructor {
		if (!is_string(_name))		__spread_log($"'_name' must be a string: {_name}", SPREAD_MESSAGE_LEVEL.ERROR);
		self.name = _name;
		if (!is_bool(_required))	__spread_log($"'_required' must be a boolean: {_required}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_bool(_is_integer))	__spread_log($"'_is_integer' must be a boolean: {_is_integer}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_real(_min))			__spread_log($"'_min' must be numeric: {_min}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_real(_max))			__spread_log($"'_max' must be numeric: {_max}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (_min > _max)			__spread_log($"'_min' must be <= '_max: {_min}, {_max}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_bool(_exclusive_min))	__spread_log($"'_exclusive_min' must be a boolean: {_exclusive_min}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_bool(_exclusive_max))	__spread_log($"'_exclusive_max' must be a boolean: {_exclusive_max}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_array(_allowed_list))	__spread_log($"'_allowed_list' must be an array: {_allowed_list}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_array(_forbidden_list))	__spread_log($"'_forbidden_list' must be an array: {_forbidden_list}", SPREAD_MESSAGE_LEVEL.ERROR);		
		if (array_length(array_intersection(_allowed_list, _forbidden_list)) > 0)	__spread_log("Allowed and forbidden lists must be non-intersecting", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_bool(_treat_as_dates))	__spread_log($"'_treat_as_dates' must be a boolean: {_treat_as_dates}", SPREAD_MESSAGE_LEVEL.ERROR);
		
		self.required = _required;
		self.is_integer = _is_integer;
		self.min = _min;
		self.max = _max;
		self.exclusive_min = _exclusive_min;
		self.exclusive_max = _exclusive_max;
		self.allowed_list = _allowed_list;
		self.forbidden_list = _forbidden_list;
		self.treat_as_dates = _treat_as_dates;
		
		static validate = function(_value) {			
			if (is_undefined(_value)) {
				return !self.required;
			}
			else {
				var _validation = true;
				if (!is_real(_value)) return false;
				if (self.is_integer)	_validation &= floor(_value) == _value;
				
				_validation &= self.exclusive_min ? (_value > self.min) : (_value >= self.min);
				_validation &= self.exclusive_max ? (_value < self.max) : (_value <= self.max);					
				
				_validation &= (array_length(self.allowed_list) == 0 ? true : array_contains(self.allowed_list, _value));
				_validation &= (array_length(self.forbidden_list) == 0 ? true : !array_contains(self.forbidden_list, _value));				
				return _validation;
			}			
		}
		
		static toString = function() {
			return string($"Spread_Num: {self.name}: required={self.required}, integer={self.is_integer}, min={self.min}, max={self.max}, exclusive_min={self.exclusive_min}, exclusive_max={self.exclusive_max}, allowed_list={self.allowed_list}, forbidden_list={self.forbidden_list}, treat_as_dates={self.treat_as_dates}");
		}
	}
	
	/**
	 * @desc	constructor for a character schema for Spread fields
	 * @param	{string}		_name 						the field name
	 * @param	{bool}			_required					whether it's required or not
	 * @param	{real}			[_min_length]=0				minimum length of the string
	 * @param	{real}			[_max_length]=infinity		maximum length of the string
	 * @param	{array}			[_allowed_list]=[]			an array with an allowed list of strings, useful for catalogs/categorical data/enums
	 * @param	{array}			[_forbidden_list]=[]		an array with a forbidden list of strings, useful for catalogs/categorical data/enums
	 * @param	{bool}			[_contains]=""				a string to check it's contained into the value
	 * @param	{bool}			[_does_not_contain]=""		a string to check it's NOT contained into the value
	 * @param	{bool}			[_starts_with]=""			a string to check whether the value starts with it
	 * @param	{bool}			[_ends_with]=""				a string to check iwhether the value ends with it
	 */
	function Spread_String(_name, _required, _min_length=0, _max_length=infinity, _allowed_list=[], _forbidden_list=[], _contains="", _does_not_contain="", _starts_with="", _ends_with="") : Spread_Schema() constructor {
		if (!is_string(_name))		__spread_log($"'_name' must be a string: {_name}", SPREAD_MESSAGE_LEVEL.ERROR);
		self.name = _name;
		if (!is_bool(_required))				__spread_log($"'_required' must be a boolean: {_required}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_real(_min_length))				__spread_log($"'_min_length' must be numeric: {_min_length}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_real(_max_length))				__spread_log($"'_max_length' must be numeric: {_max_length}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (_min_length > _max_length)			__spread_log($"'_min_length' must be <= '_max_length: {_min_length}, {_max_length}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_string(_contains))				__spread_log($"'_contains' must be a string: {_contains}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_string(_does_not_contain))		__spread_log($"'_does_not_contain' must be a string: {_does_not_contain}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_string(_starts_with))			__spread_log($"'_starts_with' must be a string: {_starts_with}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_string(_ends_with))				__spread_log($"'_ends_with' must be a string: {_ends_with}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_array(_allowed_list))			__spread_log($"'_allowed_list' must be an array: {_allowed_list}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_array(_forbidden_list))			__spread_log($"'_forbidden_list' must be an array: {_forbidden_list}", SPREAD_MESSAGE_LEVEL.ERROR);		
		if (array_length(array_intersection(_allowed_list, _forbidden_list)) > 0)	__spread_log("Allowed and forbidden lists must be non-intersecting", SPREAD_MESSAGE_LEVEL.ERROR);
		
		self.required = _required;
		self.min_length = _min_length;
		self.max_length = _max_length;
		self.allowed_list = _allowed_list;
		self.forbidden_list = _forbidden_list;
		self.contains = _contains;
		self.does_not_contain = _does_not_contain;
		self.starts_with = _starts_with;
		self.ends_with = _ends_with;
		
		static validate = function(_value) {			
			if (is_undefined(_value)) {
				return !self.required;
			}
			else {
				var _validation = true;			
				if (!is_string(_value)) return false;
				_validation &= string_length(_value) >= self.min_length && string_length(_value) <= self.max_length;
				_validation &= self.contains == "" ? true : string_pos(self.contains, _value) >= 1;
				_validation &= self.does_not_contain == "" ? true : string_pos(self.does_not_contain, _value) == 0;
				_validation &= self.starts_with == "" ? true : string_starts_with(_value, self.starts_with);
				_validation &= self.ends_with == "" ? true : string_ends_with(_value, self.ends_with);
				_validation &= (array_length(self.allowed_list) == 0 ? true : array_contains(self.allowed_list, _value));
				_validation &= (array_length(self.forbidden_list) == 0 ? true : !array_contains(self.forbidden_list, _value));
				return _validation;
			}			
			
		}
		
		static toString = function() {
			return string($"Spread_String: {self.name}: required={self.required}, min_length={self.min_length}, max_length={self.max_length}, allowed_list={self.allowed_list}, forbidden_list={self.forbidden_list}, contains={self.contains}, does_not_contain={self.does_not_contain}, starts_with={self.starts_with}, ends_with={self.ends_with}");
		}
	}
	
	
	
	/**
	 * @desc	constructor for a character schema for Spread fields
	 * @param	{string}		_name 												the field name
	 * @param	{bool}			_required											whether it's required or not
	 * @param	{bool}			[_strict]=false										whether it accepts values other than true or false (defined by the _truthy and _falsy arrays) to interpret boolean true or false
	 * @param	{bool}			[_truthy]=["true", "TRUE", true, 1, "yes", "Y"]		an array of strings and numbers that will be processed as Gamemaker true (if not strict)
	 * @param	{bool}			[_falsy]=["false", "FALSE", false, 0, "no", "N"]	an array of strings and numbers that will be processed as Gamemaker false (if not strict)
	 */
	function Spread_Boolean(_name, _required, _strict = false, _truthy = ["true", "TRUE", true, 1, "yes", "Y"], _falsy = ["false", "FALSE", false, 0, "no", "N"]) : Spread_Schema() constructor {
		if (!is_string(_name))		__spread_log($"'_name' must be a string: {_name}", SPREAD_MESSAGE_LEVEL.ERROR);
		self.name = _name;
		if (!is_bool(_required))		__spread_log($"'_required' must be a boolean: {_required}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_bool(_strict))			__spread_log($"'_strict' must be a boolean: {_strict}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_array(_truthy))			__spread_log($"'_truthy' must be an array: {_truthy}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!is_array(_falsy))			__spread_log($"'_falsy' must be an array: {_falsy}", SPREAD_MESSAGE_LEVEL.ERROR);		
		if (array_length(array_intersection(_truthy, _falsy)) > 0)	__spread_log("Allowed and forbidden lists must be non-intersecting", SPREAD_MESSAGE_LEVEL.ERROR);
		
		self.required = _required;
		self.strict = _strict;
		self.truthy = _truthy;
		self.falsy = _falsy;
		
		static validate = function(_value) {
			if (is_undefined(_value)) {
				return !self.required;
			}
			else {
				var _validation = true;
			
				if (self.strict) {
					_validation &= is_bool(_value);
				}
				else {
					_value = (array_contains(self.truthy, _value) ? true : (array_contains(self.falsy, _value) ? false : undefined));					
					_validation &= is_bool(_value);
				}
				return _validation;
			}
		}
		
		static getBoolValue = function(_value) {
			_value = (array_contains(self.truthy, _value) ? true : (array_contains(self.falsy, _value) ? false : undefined));
			return _value;
		}
		
		static toString = function() {
			return string($"Spread_Boolean: {self.name}: required={self.required}, strict={self.strict}, truthy={self.truthy}, falsy={self.falsy}");
		}
	}
	
	
	
	/**
	 * @desc	constructor for a Primary Key schema for Spread fields. ALL tables must have exactly ONE field defined with this schema. Also note IDs are required by default.
	 * @param	{string}		_name			the field name
	 */
	function Spread_ID(_name) : Spread_Schema() constructor {	
		if (!is_string(_name))		__spread_log($"'_name' must be a string: {_name}", SPREAD_MESSAGE_LEVEL.ERROR);
		self.name = _name;
		self.required = true;
		
		static validate = function(_value, _existing_values) {
			return !is_undefined(_value) && array_get_index(_existing_values, _value) == -1;
		}
		static toString = function() {
			return string($"Spread_ID: {self.name}: required={self.required} unique=1");
		}
	}
	
	
	/**
	 * @desc	constructor for a Foreign Key (FK) schema for Spread fields
	 * @param	{string}		_name 												the field name
	 * @param	{bool}			_required											whether it's required or not	 
	 * @param	{string}		_foreign_table_name									the name of the target table. MUST be defined BEFORE the current table's definition and cannot self-reference the current table
	 */
	function Spread_FK(_name, _required, _foreign_table_name) : Spread_Schema() constructor {
		if (!is_string(_name))		__spread_log($"'_name' must be a string: {_name}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (!spread_table_exists(_foreign_table_name))	__spread_log($"'_foreign_table_name' {_foreign_table_name} has not yet been defined. Note that you cannot self-reference the table being created.", SPREAD_MESSAGE_LEVEL.ERROR);
		self.name = _name;
		self.required = _required;
		self.foreign_table_name = _foreign_table_name;
		
		static validate = function(_value) {
			if (is_undefined(_value)) {
				return !self.required;
			}
			else {
				return array_get_index(spread_get_item_keys(self.foreign_table_name), _value) != -1;
			}
		}
		static toString = function() {
			return string($"Spread_FK: {self.name}: required={self.required} foreign_table_name={self.foreign_table_name}");
		}
	}
	
	
#endregion

#region Range/address management
		
	/**
	 * @desc	get properties (e.g. # of cols, # of rows) of a spreadsheet-like address or range
	 * @param	{string}	_range		The address of the range (e.g. "h4", "C1004" "b1:AB220").
	 * @param	{real}		[_idx]=0	The index to check, if the range is a range (0 for the top left cell, 1 for the bottom right cell)
	 * @returns {struct}	a struct with col and row keys
	 */
	function __spread_range_get_properties(_range, _idx=0) {
		var _rng = string_split(_range, ":");
		if (array_length(_rng) == 1)	array_push(_rng, _rng[0]);
		if (array_length(_rng) > 2 || string_length(string_letters(_rng[_idx])) == 0 || string_length(string_digits(_rng[_idx])) == 0)	__spread_log($"Invalid range provided, {_range}. Note that you cannot use named ranges with this function!", SPREAD_MESSAGE_LEVEL.ERROR);
		if (_idx < 0 || _idx > 1)	__spread_log($"Invalid index provided, {_idx}", SPREAD_MESSAGE_LEVEL.ERROR);	
			
		var _spec_range = string_upper(string_lettersdigits(_rng[_idx]));
			
		var _col = 0;
		var _i = 1;
		var _n=string_length(_spec_range);
		var _digits = false;
		while (_i<=_n && !_digits) {
			var _chr = string_copy(_spec_range, _i, 1);				
			if (ord(_chr)>64) _i++;
			else _digits = true;
		}
		_i--;
			
		for (_k = _i; _k>0; _k--) {
			var _chr = string_copy(_spec_range, _k, 1);
			_col += (ord(_chr) - 64) * power(26, _i-_k);
		}
			
		var _row = real(string_copy(_spec_range, _i+1, string_length(_spec_range)));
		return {col: _col, row: _row};
	}
			
	/**
	 * @desc	gets the area in # of cells of an address or  range
	 * @param	{string}	_range	the range to check (e.g. "A4", or "Z5:AB40")
	 * @returns {real}		the area
	 */
	function __spread_range_get_area(_range) {
		var _rng = string_split(_range, ":");
		if (array_length(_rng) == 1)	array_push(_rng, _rng[0]);
		if (array_length(_rng) > 2)	__spread_log($"Invalid range provided, {_range}. Note that you cannot use named ranges with this function!", SPREAD_MESSAGE_LEVEL.ERROR);
				
		return __spread_range_get_columns(_range) * __spread_range_get_rows(_range);
	}
	
	/**
	 * @desc	gets the number of rows of an address or  range
	 * @param	{string}	_range	the range to check (e.g. "A4", or "Z5:AB40")
	 * @returns {real}		the number of rows
	 */
	function __spread_range_get_rows(_range) {
		var _rng = string_split(_range, ":");
		if (array_length(_rng) == 1)	array_push(_rng, _rng[0]);
		if (array_length(_rng) > 2)	__spread_log($"Invalid range provided, {_range}. Note that you cannot use named ranges with this function!", SPREAD_MESSAGE_LEVEL.ERROR);
				
		var _props_top_left = __spread_range_get_properties(_range, 0);
		var _props_bottom_right = __spread_range_get_properties(_range, 1);
		if !(_props_top_left.col <= _props_bottom_right.col && _props_top_left.row <= _props_bottom_right.row)	return 0;
				
		return (_props_bottom_right.row - _props_top_left.row + 1);
	}
	
	/**
	 * @desc	gets the number of columns of an address or  range
	 * @param	{string}	_range	the range to check (e.g. "A4", or "Z5:AB40")
	 * @returns {real}		the number of columns
	 */
	function __spread_range_get_columns(_range) {
		var _rng = string_split(_range, ":");
		if (array_length(_rng) == 1)	array_push(_rng, _rng[0]);
		if (array_length(_rng) > 2)	__spread_log($"Invalid range provided, {_range}. Note that you cannot use named ranges with this function!", SPREAD_MESSAGE_LEVEL.ERROR);
				
		var _props_top_left = __spread_range_get_properties(_range, 0);
		var _props_bottom_right = __spread_range_get_properties(_range, 1);
		if !(_props_top_left.col <= _props_bottom_right.col && _props_top_left.row <= _props_bottom_right.row)	return 0;
				
		return (_props_bottom_right.col - _props_top_left.col + 1);
	}
	
	
			
	/**
	 * @desc	given a column number, gets the letter associated with the column
	 * @param	{real} _column	a column number
	 * @returns {string} the corresponding letter
	 */
	function __spread_col_to_address(_column) {				
		if (!is_numeric(_column) || floor(_column) != _column || _column < 1 || _column > 16384) __spread_log($"Invalid column number provided, {_column}", SPREAD_MESSAGE_LEVEL.ERROR);
			
		var _address = "";
				
		while (_column > 0) {
			var _remainder = (_column - 1) % 26;
			_address = chr(65 + _remainder) + _address;
			_column = floor((_column - 1) / 26);
		}

		return _address;
	}
	
	/**
	 * @desc	given a column letter, return the number
	 * @param	{string}	_address	the column specifier (e.g. "H")
	 * @returns {real}	the column number
	 */
	function __spread_address_to_col(_address) {
		if (string_length(_address) < 1 || string_letters(_address) != _address)	__spread_log($"Invalid column address provided, {_address}", SPREAD_MESSAGE_LEVEL.ERROR);
		if (string_pos(":", _address) > 0)	__spread_log($"Cannot get column number of provided range {_address} - use a single column specifier instead", SPREAD_MESSAGE_LEVEL.ERROR);
		
		_address = string_upper(_address);

		var _col = 0;

		for (var i = 1; i <= string_length(_address); i++) {
			var _char = string_char_at(_address, i);
			var _code = ord(_char);
			_col = (_col * 26) + (_code - 64);
		}

		if (_col < 1 || _col > 16384) __spread_log($"Column address out of bounds, {_address}", SPREAD_MESSAGE_LEVEL.ERROR);

		return _col;
	}
	
	function __spread_named_range_resolve(_connection_id, _sheet_id, _range_name) {
		if (!struct_exists(global.Spread.connections[$ _connection_id].named_ranges, _range_name))	return undefined;
		
		var _range_address = global.Spread.connections[$ _connection_id].named_ranges[$ _range_name].address;
		if (global.Spread.connections[$ _connection_id].named_ranges[$ _range_name].sheet != _sheet_id) {
			__spread_log(string($"Found named range {_range_name} in sheet {global.Spread.connections[$ _sheet_id].named_ranges[$ _range_name].sheet}, which resolves to {_range_address}, but it seems it was requested from sheet {_sheet_id} instead! Double check the range name and/or sheet."), SPREAD_MESSAGE_LEVEL.WARNING);						
		}
		else {
			__spread_log(string($"Found named range {_range_name} in sheet {_sheet_id}, which resolves to {_range_address}"), SPREAD_MESSAGE_LEVEL.INFO);
		}
		
		return _range_address;
	}
			
#endregion

#region Functions

	#region Helpers
		
		
		/**
		 * @desc	logs a message with specified level to the Gamemaker log, if its level is greater than or equal to the current set message level in Spread's options
		 * @param	{string}		_message_text									the text to send
		 * @param	{real}		[_message_level]=SPREAD_MESSAGE_LEVEL.SYSTEM		the message level
		 * @param	{bool}		[_exception_on_error]=true							if the level is ERROR, and this is true, it will throw an exception instead of just logging the message.
		 */
		function __spread_log(_message_text, _message_level=SPREAD_MESSAGE_LEVEL.SYSTEM, _exception_on_error=true) {
			var _callstack = debug_get_callstack();
			var _calling_from = string_replace_all( array_length(_callstack) == 1 ? _callstack[0] : _callstack[1] , "gml_Script_", "");
			_calling_from = string_split(_calling_from, ":")[0];
			if (_message_level >= SPREAD_LOG_MESSAGE_LEVEL) {
				var _message = string($"{SPREAD_LOG_PREFIX} ({global.Spread.enums[$ "MESSAGE_LEVEL"][_message_level]}):  {_calling_from}: 	{_message_text}");
				if (_message_level == SPREAD_MESSAGE_LEVEL.ERROR && _exception_on_error) {
					throw("\n"+_message);
				}
				else {
					show_debug_message(_message);
				}
			}
		}
		
		
		/**
		 * @desc	pads a number to a given width with a padding char
		 * @param	{int}			_number				the number
		 * @param	{int}			_length				the length to pad to
		 * @param	{string}		[_pad_chr]="0"		the pad char to use
		 * @returns {string}		the padded string representation of the number
		 */
		function __spread_pad(_number, _length, _pad_chr="0") {
			var _str = string(_number);
			var _n = _length - string_length(_str);
			if (_n <= 0)	return _str;
			else			return string_repeat(_pad_chr, _n) + _str;
		}
		
		#region Regex management
		
			/**
			 * @desc	escapes a string to prepare for execution with libxprocess and the regex.exe program, substituting double quotes with single quotes and replacing spaces with the set space char in options
			 * @param	{string}		_string						the string to escape
			 * @param	{string}		[_spaces_escape_char]="¬"	the escape char to use for spaces
			 * @returns {string}		the escaped string
			 */
			function __spread_regex_escape(_string, _spaces_escape_char=SPREAD_REGEX_SPACE_ESCAPE_CHAR) {			
				var _output = string_replace_all(string_replace_all(_string, chr(34), "'"), " ", _spaces_escape_char);
				return _output;
			}
		
			/**
			 * @desc	finds all matches (or all capture groups) of the regex within the string, similar to Python's findall. Automatically escapes the string
			 * @param	{string}	_string									the string to parse
			 * @param	{string}	_regex									a string with the regex to use
			 * @param	{string}	[_flags]=SPREAD_REGEX_DEFAULT_FLAGS		optional string of flags to use when processing the regex (i=ignore-case, m=multiline, s=. matches newline, x=ignore whitespaces and comments, a=ascii, u=unicode)
			 * @returns {string}	a stringified JSON array with the matches
			 */
			function __spread_regex_findall(_string, _regex, _flags=SPREAD_REGEX_DEFAULT_FLAGS) {
				var _escaped_contents = __spread_regex_escape(_string);
			
				var _process = string($"regex findall {_escaped_contents} \"{_regex}\" {_flags}");
			
				var _pid = ProcessExecute(_process);
				var _output = ExecutedProcessReadFromStandardOutput(_pid);
			
				FreeExecutedProcessStandardOutput(_pid);
				FreeExecutedProcessStandardInput(_pid);
			
				_output = string_replace_all(string_replace_all(_output, "\n", ""), "\r", "");
				return _output;
			}
		
			
			/**
			 * @desc	gets the index of the first match of the provided regex within the string. Automatically escapes the string
			 * @param	{string}	_string									the string to parse
			 * @param	{string}	_regex									a string with the regex to use
			 * @param	{string}	[_flags]=SPREAD_REGEX_DEFAULT_FLAGS		optional string of flags to use when processing the regex (i=ignore-case, m=multiline, s=. matches newline, x=ignore whitespaces and comments, a=ascii, u=unicode)
			 * @returns {real}	returns the 0-based index if there's a match or -1 if not
			 */
			function __spread_regex_search(_string, _regex, _flags=SPREAD_REGEX_DEFAULT_FLAGS) {
				var _escaped_contents = __spread_regex_escape(_string);
			
				var _process = string($"regex search {_escaped_contents} \"{_regex}\" {_flags}");
			
				var _pid = ProcessExecute(_process);
				var _output = ExecutedProcessReadFromStandardOutput(_pid);
			
				FreeExecutedProcessStandardOutput(_pid);
				FreeExecutedProcessStandardInput(_pid);
			
				_output = real(string_replace_all(string_replace_all(_output, "\n", ""), "\r", ""));
				return _output;
			}
		
			/**
			 * @desc	gets the index of the first match of the provided regex within the string. Automatically escapes the string
			 * @param	{string}	_string									the string to parse
			 * @param	{string}	_source_regex							a string with the source regex to use
			 * @param	{string}	_replacement_regex						a string with the replacement regex to use
			 * @param	{string}	[_flags]=SPREAD_REGEX_DEFAULT_FLAGS		optional string of flags to use when processing the regex (i=ignore-case, m=multiline, s=. matches newline, x=ignore whitespaces and comments, a=ascii, u=unicode)
			 * @returns {string}	the replaced string, or a stringified JSON array of replaced strings
			 */
			function __spread_regex_sub(_string, _source_regex, _replacement_regex, _flags=SPREAD_REGEX_DEFAULT_FLAGS) {
				var _escaped_contents = _string;
			
				var _process = string($"regex sub \"{_escaped_contents}\" \"{_source_regex}\" \"{_replacement_regex}\" {_flags}");
			
				var _pid = ProcessExecute(_process);
				var _output = ExecutedProcessReadFromStandardOutput(_pid);
			
				FreeExecutedProcessStandardOutput(_pid);
				FreeExecutedProcessStandardInput(_pid);
			
				_output = string_replace_all(string_replace_all(_output, "\n", ""), "\r", "");
				return _output;
			}
		
			
			/**
			 * @desc	executes a series of regex operations defined in an input JSON file and optionally outputs the result to another JSON file
			 * @param	{string}	_input_json_filename			the input JSON with the definition of the regexes. The JSON must be an array with one or more structs, with the following keys:
			 *														"instruction":	<one of the following: search|findall|split|sub>,
			 *														"string":		<the target string. mutually exclusive with string_file>,
			 *														"string_file":	<a filename to take the string from. mutually exclusive with string>,
			 *														"pattern":		<the regex to use>
			 *														"replacement":	<the replacement regex to use (only for instruction=sub)>
			 *														"flags":		<optional string of flags to use>			 
			 * @param	{string}	[_json_output_filename]=""		optional filename to store the result into
			 * @returns {string}	a stringified JSON array of the results
			 */
			function __spread_regex_json(_input_json_filename, _json_output_filename="") {
				if (!file_exists(_input_json_filename))	__spread_log(string($"__spread_regex_json: File does not exist, {_input_json_filename}"),  SPREAD_MESSAGE_LEVEL.ERROR);
				var _process = string($"regex --json \"{_input_json_filename}\" \"{_json_output_filename}\"");
			
				var _pid = ProcessExecute(_process);
				var _output = ExecutedProcessReadFromStandardOutput(_pid);
			
				FreeExecutedProcessStandardOutput(_pid);
				FreeExecutedProcessStandardInput(_pid);
			
				if (_json_output_filename == "") {
					_output = string_replace_all(string_replace_all(_output, "\n", ""), "\r", "");
					return _output;
				}
				else {
					return _output;
				}
			}
		
		#endregion
		
		/**
		 * @desc	converts HTML escape entities into actual chars
		 * @param	{string}	_string		the string to process
		 * @returns	{string}	the string with the actual characters in place
		 */
		function __spread_html_unescape(_string) {
			var _entities = {
				"&lt;": "<",
				"&gt;": ">",
				"&amp;": "&",
				"&quot;": "\"",
				"&apos;": "'",
				"&nbsp;": chr(160),
			    "&copy;": chr(169),
			    "&reg;": chr(174),
			    "&euro;": chr(8364),
			};
			
			var _ents = struct_get_names(_entities);
			var _str = _string;
			for (var _i=0, _n=array_length(_ents); _i<_n; _i++) {				
				_str = string_replace_all(_str, _ents[_i], _entities[$ _ents[_i]]);				
			}
			return _str;
		}
		
		/**
		 * @desc	generates a JSON file from a loaded Spread table
		 * @param	{string}	_table_name_id	the table name
		 * @return	{string}	the path to the JSON filename
		 */
		function __spread_generate_json_bundle(_table_name_id) {
			if (array_get_index(struct_get_names(global.Spread.tables), _table_name_id) == -1)	__spread_log(string($"Table does not exist, {_table_name_id}"), SPREAD_MESSAGE_LEVEL.ERROR);
			
			var _buffer = buffer_create(1, buffer_grow, 1);
			buffer_write(_buffer, buffer_text, json_stringify(global.Spread.tables[$ _table_name_id]));
			var _dir = string_pos("/", SPREAD_JSON_BUNDLE_PATHS) == 0 ? SPREAD_JSON_BUNDLE_PATHS+"/" : SPREAD_JSON_BUNDLE_PATHS;
			var _ext = string_pos(".", SPREAD_JSON_BUNDLE_EXTENSION) == 0 ? "."+SPREAD_JSON_BUNDLE_EXTENSION : SPREAD_JSON_BUNDLE_EXTENSION;
			var _filename = _dir+_table_name_id+_ext;
			buffer_save(_buffer, _filename);
			buffer_delete(_buffer);
			
			__spread_log(string($"Generated JSON file {_filename} from table {_table_name_id}"), SPREAD_MESSAGE_LEVEL.INFO);
			return _filename;
		}
		
		/**
		 * @desc	reads the content of a sheet from an active spreadsheet connection
		 * @param	{string}	_connection_id  the connection id
		 * @param	{string}	_sheet_id		the worksheet name
		 * @param	{string}	[_force]=false  whether to reload the contents anyway, even if the sheet was previously loaded
		 */	
		function __spread_load_xlsx_worksheet(_connection_id, _sheet_id, _force = false) {
			if (array_get_index(struct_get_names(global.Spread.connections), _connection_id) == -1)	__spread_log(string($"Connection invalid or not established with spreadsheet, {_connection_id}"), SPREAD_MESSAGE_LEVEL.ERROR);
			if (array_get_index(struct_get_names(global.Spread.connections[$ _connection_id].sheets), _sheet_id) == -1)	__spread_log(string($"Sheet {_sheet_id} not in spreadsheet {_connection_id}"), SPREAD_MESSAGE_LEVEL.ERROR);
			
			if (global.Spread.connections[$ _connection_id].sheets[$ _sheet_id].loaded && !_force) {
				__spread_log(string($"Sheet {_sheet_id} already loaded and force not specified - skipped"), SPREAD_MESSAGE_LEVEL.INFO);
				exit;
			}
			
			// Open rel sheet XML
			var _conn = global.Spread.connections[$ _connection_id];			
			var _sha1 = _conn.source_sha1;
			var _folder = _conn.connection_cache_folder;
			var _sheet_file = _conn.sheets[$ _sheet_id].file;
			var _file = string($"xl/{_sheet_file}");
			
			if (_conn.calculation_mode != "auto")	__spread_log($"Connection {_connection_id} refers to a workbook for which calculation mode is not completely automatic, '{_conn.calculation_mode}'. Remember that Spread does NOT recalculate formulas. If you want the latest values read from the worksheet, please make sure you manually recalculate and save again, or switch to automatic calculation mode", SPREAD_MESSAGE_LEVEL.WARNING);
			
			var _t = get_timer();
			
			// Perform range extractions
			var _json = [					
				{
					"instruction": "sub", // get rid of "empty" cells (due to merged ranges mainly)
					"string_file": _folder+_file,
					"pattern": "<c ([^>]+)/>",
					"replacement": "",
					"flags": SPREAD_REGEX_DEFAULT_FLAGS
				},
				{
					"instruction": "findall", // get range and content of each range
					"string": "$PREV$",
					"pattern": "<c (?P<attrs>[^>/]*?)(?:/>|>(?P<body>.*?)</c>)",
					"flags": SPREAD_REGEX_DEFAULT_FLAGS
				},
				{
					"instruction": "sub", // values
					"string": "$PREV$",
					"pattern": "<v>([^<]*)</v>",
					"replacement": "v=$1"+SPREAD_REGEX_PROCESSING_CHAR,
					"flags": SPREAD_REGEX_DEFAULT_FLAGS					
				},
				{
					"instruction": "sub", // formulas
					"string": "$PREV$",
					"pattern": "<f([^>]*)(?:/>|>([^<]*)</f>)",
					"replacement": "f=$2"+SPREAD_REGEX_PROCESSING_CHAR+"$1"+SPREAD_REGEX_PROCESSING_CHAR,
					"flags": SPREAD_REGEX_DEFAULT_FLAGS
				},
			];
			var _json_regex = json_stringify(_json);
			
			var _buffer = buffer_create(1, buffer_grow, 1);
			buffer_write(_buffer, buffer_text, _json_regex);
			buffer_save(_buffer, string($"{game_save_id}__spread_json_input_{_sha1}.json"));
			buffer_delete(_buffer);
			
			var _output = __spread_regex_json(string($"{game_save_id}__spread_json_input_{_sha1}.json"), string($"{game_save_id}__spread_json_output_{_sha1}.json"));
			
			// Read result from file
			if (!file_exists(string($"{game_save_id}__spread_json_output_{_sha1}.json")))		__spread_log($"Error while parsing sheet {_sheet_id}", SPREAD_MESSAGE_LEVEL.ERROR);
			
			var _buffer = buffer_create(1, buffer_grow, 1);
			_buffer = buffer_load(string($"{game_save_id}__spread_json_output_{_sha1}.json"));
			var _range_data = buffer_read(_buffer, buffer_text);
			buffer_delete(_buffer);
			
						
			// Process ranges
			_range_data = json_parse(_range_data);
			_range_data = _range_data[array_length(_range_data)-1];
			
				
			var _ranges = {};
			
			for (var _i=0, _n=array_length(_range_data); _i<_n; _i++) {
				var _parts = json_parse(_range_data[_i])
					
				if (array_length(_parts) != 2)	__spread_log($"Unexpected data found while parsing sheet {_sheet_id}: {_parts}", SPREAD_MESSAGE_LEVEL.ERROR);
				
				// Parse the metadata first...
				var _range_metadata = string_split(_parts[0], " ");
				
				var _key = "";
				for (var _j=0, _m=array_length(_range_metadata); _j<_m; _j++) {
					var _key_value = string_split(_range_metadata[_j], "=");
					switch(_key_value[0]) {
						case "r":
							_key = string_replace_all(_key_value[1], chr(34), "");
								
							_ranges[$ _key] = {};
							break;
						case "t":
							switch(_key_value[1]) {
								case "\"s\"": //shared  string									
								case "\"inlineStr\"": // inline
								case "\"str\"": // formula that returns a string
									_ranges[$ _key][$ "type"] = "string";
									break;
								case "\"b\"": // boolean
									_ranges[$ _key][$ "type"] = "boolean";
									break;
								case "\"e\"": // error
									_ranges[$ _key][$ "type"] = "error";
									break;
								case "\"d\"": // date
									_ranges[$ _key][$ "type"] = "number"; // date, but its a number internally
									break;
							}
							_ranges[$ _key][$ "raw_type"] = _key_value[1];
							
							break;
						break;					
						// ignore other tags						
					}


					// Default (no t tag) is number
					if (!struct_exists(_ranges[$ _key], "type")) {
						_ranges[$ _key][$ "type"] = "number";
						_ranges[$ _key][$ "raw_type"] = "";							
					}
					
				}					
					
				
				// Now parse the values/formulas
				var _range_value_formula = string_split(_parts[1], "«");
				for (var _j=0, _m=array_length(_range_value_formula); _j<_m; _j++) {
					var _tag_value = string_split(_range_value_formula[_j], "=");
					
					if (array_length(_tag_value) < 2)	continue;
						
					_tag_value[1] = string_join_ext("=", _tag_value, 1);
						
										
					var _tag = _tag_value[0];
					switch(_tag) {
						case "v": // actual value (or index of shared string)
							if (_ranges[$ _key][$ "raw_type"] == "\"s\"") { // shared string
								var _val = __spread_html_unescape( global.Spread.connections[$ _connection_id].shared_strings[ real(_tag_value[1]) ]);
							}
							else if (_ranges[$ _key][$ "raw_type"] == "\"str\"") { // string result
								var _val = __spread_html_unescape( _tag_value[1] );
							}
							else if (_ranges[$ _key][$ "raw_type"] == "\"b\"") { // bool
								var _val = bool(_tag_value[1]);
							}
							// TO DO: inline strings
							else { // get value (can be from formula or direct)
								var _val = real(_tag_value[1]);
							}
							_ranges[$ _key][$ "value"] = _val;
							break;
						case "f": // formula
							_ranges[$ _key][$ "formula"] = __spread_html_unescape( _tag_value[1] );
							break;
						// TO DO: ref= si= (shared formulas)	
					}				
				}					
					
			}
			
			
			if (file_exists(string($"{game_save_id}__spread_json_input_{_sha1}.json")))	file_delete(string($"{game_save_id}__spread_json_input_{_sha1}.json"));
			if (file_exists(string($"{game_save_id}__spread_json_output_{_sha1}.json")))	file_delete(string($"{game_save_id}__spread_json_output_{_sha1}.json"));
			
			global.Spread.connections[$ _connection_id].sheets[$ _sheet_id].data = _ranges;			
			global.Spread.connections[$ _connection_id].sheets[$ _sheet_id].loaded = true;
			global.Spread.connections[$ _connection_id].sheets[$ _sheet_id].last_loaded_datetime = date_current_datetime();
			
			__spread_log(string($"Loaded contents of sheet {_sheet_id} of connection {_connection_id}, in {(get_timer()-_t)/1000000} seconds"), SPREAD_MESSAGE_LEVEL.INFO);
		}
		
	#endregion

	#region API
	
		#region XLSX
	
			/**
			 * @desc	Establishes a connection to an XLSX file
			 * @param	{string}	_filename				the XLSX filename, which must reside in the %LOCALAPPDATA%\Spread folder (e.g. C:\Users\<Username>\AppData\Local\Spread.
			 *												NOTE: It's highly recommended not to place XLSX files in the datafiles/ folder of your project, as you can inadvertently ship these; also, live editing and reloading will not be possible.
			 * @param	{string}	_connection_name		a unique identifer to name the connection (e.g. "db_items", etc.)
			 * @param	{bool}		_force					whether to redo the connection
			 * @returns {bool}		whether the connection was succcessful
			 */
			function spread_connect_xlsx(_filename, _connection_name, _force=false) {
				if (!is_bool(_force))	__spread_log(string($"'_force' must be boolean, {_force}"), SPREAD_MESSAGE_LEVEL.ERROR);
				if (!_force && struct_exists(global.Spread.connections, _connection_name))		__spread_log(string($"Connection already exists, {_connection_name}, type {global.Spread.connections[$ _connection_name].connection_type}, pointing to {global.Spread.connections[$ _connection_name].connection_source}, and force was not specified"), SPREAD_MESSAGE_LEVEL.ERROR);
				
				// Handle prod mode
				if ( spread_prod_mode() ) {
					__spread_log(string($"Prod mode detected, skipping XLSX connection"),  SPREAD_MESSAGE_LEVEL.INFO);
					//if (file_exists(_filename))		__spread_log(string($"Prod mode detected - removing the source XLSX {_filename} is highly recommended"),  SPREAD_MESSAGE_LEVEL.WARNING);
					exit;
				}
				
				if (!file_exists(_filename))	__spread_log(string($"File does not exist, {_filename}"),  SPREAD_MESSAGE_LEVEL.ERROR);
			
			
				// Get file SHA1
				var _buffer = buffer_create(1, buffer_grow, 1);
				_buffer = buffer_load(_filename);
				var _sha1 = buffer_sha1(_buffer, 0, buffer_get_size(_buffer));
				buffer_delete(_buffer);
			
				// Delete old directory
				var _folder = string($"{game_save_id}spread_{_sha1}_contents/");	
				if (directory_exists(_folder)) directory_destroy(_folder);				
				
			
				// Unzip the XLSX
				zip_unzip(_filename, _folder);
			
				if (!directory_exists(_folder))		__spread_log(string($"Could not process contents of XLSX spreadsheet, {_filename}"),  SPREAD_MESSAGE_LEVEL.ERROR);
			
				global.Spread.connections[$ _connection_name] = {
					connection_type: "XLSX",
					connection_source: _filename,
					connection_cache_folder: _folder,
					source_sha1: _sha1,
					connection_established: date_datetime_string(date_current_datetime()),
					title: undefined,
					creator: undefined,
					last_modified_by: undefined,
					date_created: undefined,
					date_modified: undefined,
					subject: undefined,
					description: undefined,
					application: undefined,
					application_version: undefined,
					calculation_mode: undefined,
					sheets: {},
					tables: {},
				};
				
				
				
				#region Load workbook metadata
			
					var _t = get_timer();
			
					// Perform extractions and subs
					var _json = [					
						{
							"instruction": "findall", // title
							"string_file": _folder+"/docProps/core.xml",
							"pattern": "<dc:title[^>]*>([^<]*)</dc:title>",
							"flags": SPREAD_REGEX_DEFAULT_FLAGS
						},
						{
							"instruction": "findall", // creator
							"string_file": _folder+"/docProps/core.xml",
							"pattern": "<dc:creator[^>]*>([^<]*)</dc:creator>",
							"flags": SPREAD_REGEX_DEFAULT_FLAGS
						},
						{
							"instruction": "findall", // last modified by
							"string_file": _folder+"/docProps/core.xml",
							"pattern": "<cp:lastModifiedBy[^>]*>([^<]*)</cp:lastModifiedBy>",
							"flags": SPREAD_REGEX_DEFAULT_FLAGS
						},
						{
							"instruction": "findall", // date created
							"string_file": _folder+"/docProps/core.xml",
							"pattern": "<dcterms:created[^>]*>([^<]*)</dcterms:created>",
							"flags": SPREAD_REGEX_DEFAULT_FLAGS
						},
						{
							"instruction": "findall", // date modified
							"string_file": _folder+"/docProps/core.xml",
							"pattern": "<dcterms:modified[^>]*>([^<]*)</dcterms:modified>",
							"flags": SPREAD_REGEX_DEFAULT_FLAGS
						},
						{
							"instruction": "findall", // subject
							"string_file": _folder+"/docProps/core.xml",
							"pattern": "<dc:subject[^>]*>([^<]*)</dc:subject>",
							"flags": SPREAD_REGEX_DEFAULT_FLAGS
						},
						{
							"instruction": "findall", // description
							"string_file": _folder+"/docProps/core.xml",
							"pattern": "<dc:description[^>]*>([^<]*)</dc:description>",
							"flags": SPREAD_REGEX_DEFAULT_FLAGS
						},
					];
					var _json_regex = json_stringify(_json);
			
					var _buffer = buffer_create(1, buffer_grow, 1);
					buffer_write(_buffer, buffer_text, _json_regex);
					buffer_save(_buffer, string($"{game_save_id}__spread_json_input_{_sha1}.json"));
					buffer_delete(_buffer);
			
					var _output = __spread_regex_json(string($"{game_save_id}__spread_json_input_{_sha1}.json"), string($"{game_save_id}__spread_json_output_{_sha1}.json"));
			
					// Read result from file
					if (!file_exists(string($"{game_save_id}__spread_json_output_{_sha1}.json")))		__spread_log("Error while parsing workbook metadata", SPREAD_MESSAGE_LEVEL.ERROR);
			
					var _buffer = buffer_create(1, buffer_grow, 1);
					_buffer = buffer_load(string($"{game_save_id}__spread_json_output_{_sha1}.json"));
					var  _metadata = json_parse(buffer_read(_buffer, buffer_text));
					buffer_delete(_buffer);
			
					// Assign metadata
					if (array_length(_metadata[0]) > 0)		global.Spread.connections[$ _connection_name].title = _metadata[0][0];
					if (array_length(_metadata[1]) > 0)		global.Spread.connections[$ _connection_name].creator = _metadata[1][0];
					if (array_length(_metadata[2]) > 0)		global.Spread.connections[$ _connection_name].last_modified_by = _metadata[2][0];
					if (array_length(_metadata[3]) > 0)		global.Spread.connections[$ _connection_name].date_created = _metadata[3][0];
					if (array_length(_metadata[4]) > 0)		global.Spread.connections[$ _connection_name].date_modified = _metadata[4][0];
					if (array_length(_metadata[5]) > 0)		global.Spread.connections[$ _connection_name].subject = _metadata[5][0];
					if (array_length(_metadata[6]) > 0)		global.Spread.connections[$ _connection_name].description = _metadata[6][0];
			
					__spread_log(string($"Parsed workbook metadata in {(get_timer()-_t)/1000000} seconds"), SPREAD_MESSAGE_LEVEL.INFO);
				
				#endregion
		
		
				#region Load spreadsheet application metadata
			
					var _t = get_timer();
			
			
					// Perform extractions and subs
					var _json = [					
						{
							"instruction": "findall", // application
							"string_file": _folder+"/docProps/app.xml",
							"pattern": "<Application[^>]*>([^<]*)</Application>",
							"flags": SPREAD_REGEX_DEFAULT_FLAGS
						},
						{
							"instruction": "findall", // creator
							"string_file": _folder+"/docProps/app.xml",
							"pattern": "<AppVersion[^>]*>([^<]*)</AppVersion>",
							"flags": SPREAD_REGEX_DEFAULT_FLAGS
						},
					];
					var _json_regex = json_stringify(_json);
			
					var _buffer = buffer_create(1, buffer_grow, 1);
					buffer_write(_buffer, buffer_text, _json_regex);
					buffer_save(_buffer, string($"{game_save_id}__spread_json_input_{_sha1}.json"));
					buffer_delete(_buffer);
			
					var _output = __spread_regex_json(string($"{game_save_id}__spread_json_input_{_sha1}.json"), string($"{game_save_id}__spread_json_output_{_sha1}.json"));
			
					// Read result from file
					if (!file_exists(string($"{game_save_id}__spread_json_output_{_sha1}.json")))		__spread_log("Error while parsing app metadata", SPREAD_MESSAGE_LEVEL.ERROR);
			
					var _buffer = buffer_create(1, buffer_grow, 1);
					_buffer = buffer_load(string($"{game_save_id}__spread_json_output_{_sha1}.json"));
					var  _metadata = json_parse(buffer_read(_buffer, buffer_text));
					buffer_delete(_buffer);
			
					// Assign metadata
					if (array_length(_metadata[0]) > 0)		global.Spread.connections[$ _connection_name].application = _metadata[0][0];
					if (array_length(_metadata[1]) > 0)		global.Spread.connections[$ _connection_name].application_version = _metadata[1][0];
				
					__spread_log(string($"Parsed app metadata in {(get_timer()-_t)/1000000} seconds"), SPREAD_MESSAGE_LEVEL.INFO);
				
				#endregion
				
				
				#region Load workbook sheets metadata
			
					var _t = get_timer();
			
					// Perform extractions and subs
					var _json = [
						{
							"instruction": "findall", // calculation mode
							"string_file": _folder+"/xl/workbook.xml",
							"pattern": " calcMode=\"([^\"]+)\"",
							"flags": SPREAD_REGEX_DEFAULT_FLAGS
						},
						{
							"instruction": "findall", // defined names (only ranges are parsed)
							"string_file": _folder+"/xl/workbook.xml",
							"pattern": "<definedName name=\"([^\"]+)\"[^>]*>([^!]*)!?([A-Za-z0-9\$:]*)</definedName>",
							"flags": SPREAD_REGEX_DEFAULT_FLAGS
							
						},
						{
							"instruction": "sub",
							"string_file": _folder+"/xl/workbook.xml",
							"pattern": "(\"[^\"]*\") ",
							"replacement": "${1},",
							"flags": SPREAD_REGEX_DEFAULT_FLAGS
						},
						{
							"instruction": "findall",
							"string": "$PREV$",
							"pattern": "<sheet ([^\/]+)/>",
							"flags": SPREAD_REGEX_DEFAULT_FLAGS
						},
						{
							"instruction": "sub",
							"string": "$PREV$",
							"pattern": "=",
							"replacement": ":",
							"flags": SPREAD_REGEX_DEFAULT_FLAGS
						},
						{
							"instruction": "sub",
							"string": "$PREV$",
							"pattern": "([^\",]+):",
							"replacement": "\"$1\":",
							"flags": SPREAD_REGEX_DEFAULT_FLAGS
						},
				
					];
					var _json_regex = json_stringify(_json);
			
					var _buffer = buffer_create(1, buffer_grow, 1);
					buffer_write(_buffer, buffer_text, _json_regex);
					buffer_save(_buffer, string($"{game_save_id}__spread_json_input_{_sha1}.json"));
					buffer_delete(_buffer);
			
					var _output = __spread_regex_json(string($"{game_save_id}__spread_json_input_{_sha1}.json"), string($"{game_save_id}__spread_json_output_{_sha1}.json"));
			
					// Read result from file
					if (!file_exists(string($"{game_save_id}__spread_json_output_{_sha1}.json")))		__spread_log("Error while parsing sheet names", SPREAD_MESSAGE_LEVEL.ERROR);
			
					var _buffer = buffer_create(1, buffer_grow, 1);
					_buffer = buffer_load(string($"{game_save_id}__spread_json_output_{_sha1}.json"));
					var  _sheets = json_parse(buffer_read(_buffer, buffer_text));
					buffer_delete(_buffer);
			
					// Calculation mode
					global.Spread.connections[$ _connection_name].calculation_mode = (array_length(_sheets[0]) == 0) ? "auto" : _sheets[0][0];
					
					// Named ranges
					global.Spread.connections[$ _connection_name].named_ranges = {};
					for (var _i=0, _n=array_length(_sheets[1]); _i<_n; _i++) {
						if (array_length( _sheets[1][_i] ) == 3) {
							global.Spread.connections[$ _connection_name].named_ranges[$ _sheets[1][_i][0]] = {
								"sheet": _sheets[1][_i][1],
								"address": _sheets[1][_i][2],
							}
						}
					}
				
					// Sheets
					array_foreach(_sheets[array_length(_sheets)-1], method({_connection_name}, function(_elem) {
						var _sheet = json_parse("{"+_elem+"}");			
						global.Spread.connections[$ _connection_name].sheets[$ _sheet.name] = {						
							workbook_sheet_id: real(_sheet.sheetId),
							sheet_id: _sheet[$"r:id"],
						};
					}));
				
				
					// Perform extractions
					var _json = [
						{
							"instruction": "findall", // relationships
							"string_file": _folder+"/xl/_rels/workbook.xml.rels",
							"pattern": "Id=(\"[^\"]+\").*?Target=(\"[^\"]+\")",
							"flags": SPREAD_REGEX_DEFAULT_FLAGS
						},
					];
					var _json_regex = json_stringify(_json);
			
					var _buffer = buffer_create(1, buffer_grow, 1);
					buffer_write(_buffer, buffer_text, _json_regex);
					buffer_save(_buffer, string($"{game_save_id}__spread_json_input_{_sha1}.json"));
					buffer_delete(_buffer);
			
					var _output = __spread_regex_json(string($"{game_save_id}__spread_json_input_{_sha1}.json"), string($"{game_save_id}__spread_json_output_{_sha1}.json"));
			
					// Read result from file
					if (!file_exists(string($"{game_save_id}__spread_json_output_{_sha1}.json")))		__spread_log("Error while parsing sheet relationships", SPREAD_MESSAGE_LEVEL.ERROR);
				
					var _buffer = buffer_create(1, buffer_grow, 1);
					_buffer = buffer_load(string($"{game_save_id}__spread_json_output_{_sha1}.json"));
					var  _sheet_rels = json_parse(buffer_read(_buffer, buffer_text));
					buffer_delete(_buffer);
				
				
					// Assign worksheet xml file name to each sheet
					var _sheets = struct_get_names(global.Spread.connections[$ _connection_name].sheets);
					for (var _i=0, _n=array_length(_sheets); _i<_n; _i++) {
						var _key = _sheets[_i];
						var _rid = global.Spread.connections[$ _connection_name].sheets[$ _key].sheet_id;
					
						var _idx = array_find_index(_sheet_rels[0], method({_rid}, function(_value) {
							return _value[0] == string($"\"{_rid}\"");
						}));
					
						global.Spread.connections[$ _connection_name].sheets[$ _key][$ "file"] = string_replace_all(_sheet_rels[0][_idx][1], chr(34), "");
						global.Spread.connections[$ _connection_name].sheets[$ _key][$ "loaded"] = false;
						global.Spread.connections[$ _connection_name].sheets[$ _key][$ "last_loaded_datetime"] = undefined;
					}
				
				
					__spread_log(string($"Found the following sheets in the workbook: {struct_get_names(global.Spread.connections[$ _connection_name].sheets)}"), SPREAD_MESSAGE_LEVEL.INFO);
					__spread_log(string($"Parsed workbook sheets in {(get_timer()-_t)/1000000} seconds"), SPREAD_MESSAGE_LEVEL.INFO);
				
				#endregion

				
				#region Load shared strings
			
					if (file_exists(_folder+"/xl/sharedStrings.xml")) {
						
						var _t = get_timer();
					
						// Perform extractions and subs
						var _json = [					
							{
								"instruction": "findall", // strings
								"string_file": _folder+"/xl/sharedStrings.xml",
								"pattern": "<si><t[^>]*?>([^<]+)</t></si>",
								"flags": SPREAD_REGEX_DEFAULT_FLAGS
							}
						];
						var _json_regex = json_stringify(_json);
			
						var _buffer = buffer_create(1, buffer_grow, 1);
						buffer_write(_buffer, buffer_text, _json_regex);
						buffer_save(_buffer, string($"{game_save_id}__spread_json_input_{_sha1}.json"));
						buffer_delete(_buffer);
			
						var _output = __spread_regex_json(string($"{game_save_id}__spread_json_input_{_sha1}.json"), string($"{game_save_id}__spread_json_output_{_sha1}.json"));
			
						// Read result from file
						if (!file_exists(string($"{game_save_id}__spread_json_output_{_sha1}.json")))		__spread_log("Error while parsing shared strings", SPREAD_MESSAGE_LEVEL.ERROR);
			
						var _buffer = buffer_create(1, buffer_grow, 1);
						_buffer = buffer_load(string($"{game_save_id}__spread_json_output_{_sha1}.json"));
						var  _strings = json_parse(buffer_read(_buffer, buffer_text));
						buffer_delete(_buffer);
				
						global.Spread.connections[$ _connection_name].shared_strings = _strings[0];
				
						__spread_log(string($"Parsed shared strings in {(get_timer()-_t)/1000000} seconds"), SPREAD_MESSAGE_LEVEL.INFO);
					}
					else {
						global.Spread.connections[$ _connection_name].shared_strings = [];
					}
				
			
				#endregion
						
				
				if (file_exists(string($"{game_save_id}__spread_json_input_{_sha1}.json")))	file_delete(string($"{game_save_id}__spread_json_input_{_sha1}.json"));
				if (file_exists(string($"{game_save_id}__spread_json_output_{_sha1}.json")))	file_delete(string($"{game_save_id}__spread_json_output_{_sha1}.json"));
			
				__spread_log($"Connection named {_connection_name} successfully established to XLSX file {_filename}", SPREAD_MESSAGE_LEVEL.INFO);
				//show_debug_message(global.Spread.connections[$ _connection_name]);
			
				return true;
			}
			
			
			/**
			 * @desc	Disconnects from an active Spread connection
			 * @param	{string}	_connection_name	The unique ID of the connection
			 * @return	{boolean}	true
			 */
			function spread_disconnect(_connection_name) {
				// Handle prod mode
				if ( spread_prod_mode() ) {
					__spread_log(string($"Prod mode detected - no XLSX disconnection established"),  SPREAD_MESSAGE_LEVEL.INFO);
					exit;
				}
				
				if (!struct_exists(global.Spread.connections, _connection_name))		__spread_log(string($"Connection {_connection_name} does not exist"), SPREAD_MESSAGE_LEVEL.ERROR);
				var _conn = global.Spread.connections[$ _connection_name];
				
				
				if (_conn.connection_type == "XLSX") {
					if (directory_exists(_conn.connection_cache_folder)) directory_destroy(_conn.connection_cache_folder);
				}
				
				struct_remove(global.Spread.connections, _connection_name);
				
				__spread_log($"Disconnected from connection {_connection_name} (source file: {_conn.connection_source})", SPREAD_MESSAGE_LEVEL.INFO);
				
				return true;
			}
			
			
			/**
			 * @desc	Defines a new table from a range of a worksheet of an active spreadsheet connection
			 * @param	{string}	_table_name_id												a unique identifier for the table (e.g. tbl_potions, etc.)
			 * @param	{string}	_connection_id												the connection id
			 * @param	{string}	_sheet_id													the worksheet name
			 * @param	{string}	_range_address_or_name										the range address (e.g. B2:U67) or named range (e.g. RangeItems) to fetch
			 * @param	{array}		_field_definition											an array of Spread_Schema items, defining the name of the key (i.e. field) and the schema used to validate that field
			 *																					the array must be of the same size as the # of columns (if the shape is rows) or the # of rows (if the shape is columns)
			 *																					for each position of the array, a field will be configured in the destination table, and data will be validated against the corresponding schema
			 *																					NOTE: exactly one of the schemas MUST have Spread_ID schema
			 * @param	{real}		[_item_offset=0]												0-based index of the row/col from which to start reading values
			 * @param	{enum}		[_shape_is_rows=true]										whether each row represents a data point (if true) or whether each column represents a data point (false)			 
			 * @param	{boolean}	[_error_on_schema_validation_fail=true]						whether to throw an exception if the data does not match the defined schema
			 * @param	{string}	[_item_validation_function=function() { return true; }]		optional function that operates on an item-by-item basis and validates it. Useful for cross-field logic. 
			 *																					Must have one parameter that reads a specific item struct (without the key) and must return a boolean.
			 * @param	{string}	[_table_validation_function=function() { return true; }]	optional function that operates on a table basis and validates it. Useful for checksums and other inter-item validations.
			 *																					Must have one parameter that reads the complete table (struct of structs) and must return a boolean.
			 * @param	{string}	[_force]=false												whether to reload the contents anyway, even if the sheet was previously loaded			 
			 * @return	{boolean}	true
			 */
			function spread_define_table(_table_name_id, _connection_id, _sheet_id, _range_address_or_name, _field_definition, _item_offset = 0, _shape_is_rows=true,  _error_on_schema_validation_fail=true, _item_validation_function = function() { return true; }, _table_validation_function = function() { return true; }, _force = false) {
				if (!_force && array_get_index(struct_get_names(global.Spread.tables), _table_name_id) != -1)	__spread_log(string($"Table name already exists, {_table_name_id}"), SPREAD_MESSAGE_LEVEL.ERROR);
				
				// Handle prod mode
				if ( spread_prod_mode() ) {
					__spread_log(string($"Prod mode detected - importing the JSON bundle instead"),  SPREAD_MESSAGE_LEVEL.INFO);
					var _dir = (string_pos("/", SPREAD_JSON_BUNDLE_PATHS) == 0 ? SPREAD_JSON_BUNDLE_PATHS+"/" : SPREAD_JSON_BUNDLE_PATHS);
					var _ext = string_pos(".", SPREAD_JSON_BUNDLE_EXTENSION) == 0 ? "."+SPREAD_JSON_BUNDLE_EXTENSION : SPREAD_JSON_BUNDLE_EXTENSION;
					var _filename = _dir+_table_name_id+_ext;
					if (!file_exists(_filename))		__spread_log(string($"No JSON bundle found for {_table_name_id} at {_filename}"),  SPREAD_MESSAGE_LEVEL.ERROR);
					
					var _buffer = buffer_create(1, buffer_grow, 1);
					_buffer = buffer_load(_filename);
					var _ranges = json_parse(buffer_read(_buffer, buffer_text));
					buffer_delete(_buffer);
					
					global.Spread.tables[$ _table_name_id] = _ranges;
					global.Spread.table_metadata[$ _table_name_id] = {
						source_type: "JSON",
						source_connection: undefined, 
						source_sheet: undefined,
						source_table: _table_name_id,
						source_range: undefined,
						source_offset: undefined,
						table_loaded: date_datetime_string(date_current_datetime()),
						table_sha1: sha1_string_utf8(json_stringify(_ranges)),
						output_json_bundle_filename: _filename,			
						
						field_definition: _field_definition,
						item_offset: _item_offset,
						shape_is_rows: _shape_is_rows,
						error_on_schema_validation_fail: _error_on_schema_validation_fail,
						item_validation_function: _item_validation_function,
						table_validation_function: _table_validation_function,		
					};	
					
					exit;
				}
				
				if (array_get_index(struct_get_names(global.Spread.connections), _connection_id) == -1)	__spread_log(string($"Connection invalid or not established with spreadsheet, {_connection_id}"), SPREAD_MESSAGE_LEVEL.ERROR);
				if (array_get_index(struct_get_names(global.Spread.connections[$ _connection_id].sheets), _sheet_id) == -1)	__spread_log(string($"Sheet {_sheet_id} not in spreadsheet {_connection_id}"), SPREAD_MESSAGE_LEVEL.ERROR);
				if (!is_array(_field_definition))	__spread_log(string($"_field_definition must be an array with items of type Spread_Schema, {_field_definition}"), SPREAD_MESSAGE_LEVEL.ERROR);
				if (!is_bool(_shape_is_rows))	__spread_log(string($"'shape_is_rows' must be boolean, {_shape_is_rows}"), SPREAD_MESSAGE_LEVEL.ERROR);
				if (!is_bool(_error_on_schema_validation_fail))	__spread_log(string($"'_error_on_schema_validation_fail' must be boolean, {_error_on_schema_validation_fail}"), SPREAD_MESSAGE_LEVEL.ERROR);
				if (!is_bool(_force))	__spread_log(string($"'_force' must be boolean, {_force}"), SPREAD_MESSAGE_LEVEL.ERROR);
				
				if (!is_callable(_item_validation_function))	__spread_log(string($"Item-level validation function provided is invalid"), SPREAD_MESSAGE_LEVEL.ERROR);
				if (!is_callable(_table_validation_function))	__spread_log(string($"Table-level validation function provided is invalid"), SPREAD_MESSAGE_LEVEL.ERROR);
				
				__spread_log(string($"Defining table [{_table_name_id}] from range [{_range_address_or_name}] of sheet [{_sheet_id}] of connection [{_connection_id}]..."), SPREAD_MESSAGE_LEVEL.INFO);			
				
				// Process named range
				var _resolved_address = __spread_named_range_resolve(_connection_id, _sheet_id, _range_address_or_name);
				if (_resolved_address != undefined)	_range_address_or_name = _resolved_address;
				
				
				var _expected_fields = _shape_is_rows ? __spread_range_get_columns(_range_address_or_name) : __spread_range_get_rows(_range_address_or_name);
				var _expected_items = _shape_is_rows ? __spread_range_get_rows(_range_address_or_name) : __spread_range_get_columns(_range_address_or_name);
				
				if (!is_numeric(_item_offset) || floor(_item_offset) != _item_offset || _item_offset < 0 || _item_offset >= _expected_items)	__spread_log(string($"Invalid item offset, {_item_offset}, must be integer and within the number of items in range"), SPREAD_MESSAGE_LEVEL.ERROR);
				if (array_length(_field_definition) != _expected_fields)	__spread_log(string($"_field_definition array must be of size {_expected_fields}, since the chosen shape is {_shape_is_rows ? "rows" : "columns"} and provided range is {_range_address_or_name}"), SPREAD_MESSAGE_LEVEL.ERROR);
				var _num_id = 0;
				var _key_field_idx = undefined;
				var _field_names = [];
				for (var _i=0, _n=array_length(_field_definition); _i<_n; _i++) {
					var _elem = _field_definition[_i];
					if (!is_instanceof(_elem, Spread_Schema))	__spread_log($"Field definition at index {_i} is not a Spread Schema.", SPREAD_MESSAGE_LEVEL.ERROR);
					
					if (array_get_index(_field_names, _elem.name) != -1) {
						__spread_log(string($"Duplicate field name in field definition, {_elem.name}"), SPREAD_MESSAGE_LEVEL.ERROR);
					}
					else {
						array_push(_field_names, _elem.name);
					}
					
					if (is_instanceof(_elem, Spread_ID)) {
						_num_id++;
						_key_field_idx = _i;
					}					
				}
				
				if (_num_id != 1)	__spread_log(string($"There must be exactly one field defined as key or Spread_ID, instead got {_num_id}"), SPREAD_MESSAGE_LEVEL.ERROR);
						
				
						
				
				// Start 
				var _rng = string_split(_range_address_or_name, ":");
				if (array_length(_rng) == 1)	array_push(_rng, _rng[0]);
				if (array_length(_rng) > 2 || string_length(string_letters(_rng[0])) == 0 || string_length(string_digits(_rng[0])) == 0 || string_length(string_letters(_rng[1])) == 0 || string_length(string_digits(_rng[1])) == 0)	__spread_log($"Invalid range provided, {_range_address_or_name}", SPREAD_MESSAGE_LEVEL.ERROR);
				
				_rng[0] = string_upper(string_lettersdigits(_rng[0]));
				_rng[1] = string_upper(string_lettersdigits(_rng[1]));
				
				// Load (if necessary)
				__spread_load_xlsx_worksheet(_connection_id, _sheet_id, _force);
				
				var _t = get_timer();
				
				var _ranges = {};
				
				var _col_top_left = real(__spread_address_to_col( string_letters(_rng[0]) ));
				var _row_top_left = real(string_digits(_rng[0]));
				var _col_bottom_right = real(__spread_address_to_col( string_letters(_rng[1]) ));
				var _row_bottom_right = real(string_digits(_rng[1]));
				
				
				var _item_min = _shape_is_rows ? _row_top_left : _col_top_left;
				var _item_max = _shape_is_rows ? _row_bottom_right : _col_bottom_right;
				var _field_min = _shape_is_rows ? _col_top_left : _row_top_left;
				var _field_max = _shape_is_rows ? _col_bottom_right : _row_bottom_right;
				
				var _existing_id_values = [];
				
				for (var _item_num = _item_min + _item_offset; _item_num <= _item_max; _item_num++) {
					var _key = "";
					var _values = {};
					for (var _field_num = _field_min; _field_num <= _field_max; _field_num++) {						
						var _cell = _shape_is_rows ? __spread_col_to_address(_field_num)+string(_item_num) : __spread_col_to_address(_item_num)+string(_field_num);
						var _field = _field_definition[_field_num-_field_min];
						
						if (struct_exists(global.Spread.connections[$ _connection_id].sheets[$ _sheet_id].data, _cell)) {			
							// Field-level validation vs schema
							var _value = global.Spread.connections[$ _connection_id].sheets[$ _sheet_id].data[$ _cell].value;
							var _type = global.Spread.connections[$ _connection_id].sheets[$ _sheet_id].data[$ _cell].type;
							
							if (_field.validate(_value, _existing_id_values)) {
								if (_field_num-_field_min == _key_field_idx) {									
									_key = _value;
									array_push(_existing_id_values, _key);
								}
								else {
									// Dates
									if (is_instanceof(_field, Spread_Num) && _field.treat_as_dates) {
										var _date = date_inc_day(date_create_datetime(1970, 1, 1, 0, 0, 0), _value-25569);										
										_values[$ _field.name] = string(date_get_year(_date)) + "-" + __spread_pad(date_get_month(_date), 2) + "-" + __spread_pad(date_get_day(_date), 2);
									}
									else if (is_instanceof(_field, Spread_Boolean)) {
										_values[$ _field.name] = _field.getBoolValue(_value);
									}
									else {
										_values[$ _field.name] = _value;
									}
								}
							}
							else if (_field_num-_field_min == _key_field_idx) {
								var _key_error_text = _error_on_schema_validation_fail ? " ": "Ignoring '_error_on_schema_validation_fail' since keys cannot fail the validation! ";								
								__spread_log($"Cell {_cell} equals [{_value}] (spreadsheet type [{_type}]), reading field [{_field.name}] which is a key. {_key_error_text}Schema: {_field}", SPREAD_MESSAGE_LEVEL.ERROR);
							}
							else {								
								var _additional_msg = _error_on_schema_validation_fail ? "" : " and will be set to undefined to continue processing, because '_error_on_schema_validation_fail' was set to false.";
								__spread_log($"Cell {_cell} equals [{_value}] (spreadsheet type [{_type}]), reading field [{_field.name}]; this does not match the defined field schema{_additional_msg}. Schema: {_field}", SPREAD_MESSAGE_LEVEL.ERROR, _error_on_schema_validation_fail);
								_values[$ _field.name] = undefined;
							}							
						}
						else if (_field.required) {
							var _key_error_text = _field_num-_field_min == _key_field_idx ? " because it is marked as a key" : "";
							__spread_log($"Cell {_cell} is blank in spreadsheet, reading field [{_field.name}], but the defined field schema marks it as required{_key_error_text}. Schema: {_field}", SPREAD_MESSAGE_LEVEL.ERROR, _error_on_schema_validation_fail);
							_values[$ _field.name] = undefined;
						}
						else {
							__spread_log($"Skipping {_cell} since it's blank in spreadsheet (but field schema for {_field.name} is set as not required), setting field to undefined", SPREAD_MESSAGE_LEVEL.INFO);
							_values[$ _field.name] = undefined;
						}
					}
					
					// Item-level check
					if (_item_validation_function(_values)) {					
						_ranges[$ _key] = _values;
					}
					else {
						var _additional_msg = _error_on_schema_validation_fail ? "" : " Processing will continue anyway because '_error_on_schema_validation_fail' was set to false.";
						__spread_log($"Fields for the current key [{_key}] individually match their schemas, but fail the provided item-level validation function.{_additional_msg}", SPREAD_MESSAGE_LEVEL.ERROR, _error_on_schema_validation_fail);
						_ranges[$ _key] = _values;
					}
				}
				
				// Table-level check
				if (_table_validation_function(_ranges)) {				
					global.Spread.tables[$ _table_name_id] = _ranges;
				}
				else {
					var _additional_msg = _error_on_schema_validation_fail ? "" : " Processing will continue anyway because '_error_on_schema_validation_fail' was set to false.";
					__spread_log($"All fields validate OK, but the complete table fails the provided table-level validation function.{_additional_msg}", SPREAD_MESSAGE_LEVEL.ERROR, _error_on_schema_validation_fail);
					global.Spread.tables[$ _table_name_id] = _ranges;
				}
				
				__spread_log(string($"Loaded table {_table_name_id} from range {_range_address_or_name} of sheet {_sheet_id} of connection {_connection_id}, in {(get_timer()-_t)/1000000} seconds"), SPREAD_MESSAGE_LEVEL.INFO);			
				
				var _filename = __spread_generate_json_bundle(_table_name_id);				
				
				global.Spread.table_metadata[$ _table_name_id] = {
					source_type: "XLSX",
					source_connection: _connection_id, 
					source_table: _table_name_id,
					source_sheet: _sheet_id,
					source_range: _range_address_or_name,
					source_offset: _item_offset,
					table_loaded: date_datetime_string(date_current_datetime()),
					table_sha1: sha1_string_utf8(json_stringify(_ranges)),
					output_json_bundle_filename: _filename,
					
					field_definition: _field_definition,
					item_offset: _item_offset,
					shape_is_rows: _shape_is_rows,
					error_on_schema_validation_fail: _error_on_schema_validation_fail,
					item_validation_function: _item_validation_function,
					table_validation_function: _table_validation_function,					
				};
				
				return true;
			}
			
			/**
			 * @desc	Forces reload of a previously defined table. Use within try...catch statements to prevent replacing previously loaded good data with failed/incomplete data and/or avoid your game tests from crashing. Cannot be used in prod mode.
			 * @param {any} _table_name_id Description
			 */
			function spread_reload_table(_table_name_id) {
				if (spread_prod_mode())	__spread_log(string($"Cannot reload tables in PROD mode, {_table_name_id}"), SPREAD_MESSAGE_LEVEL.ERROR);
				if (array_get_index(struct_get_names(global.Spread.tables), _table_name_id) == -1)	__spread_log(string($"Table name does not exist, {_table_name_id}"), SPREAD_MESSAGE_LEVEL.ERROR);
				
				var _metadata = global.Spread.table_metadata[$ _table_name_id];
				if (!struct_exists(global.Spread.connections, _metadata.source_connection))	__spread_log(string($"Source XLSX/sheet has disconnected, {_metadata.source_connection}"), SPREAD_MESSAGE_LEVEL.ERROR);
				
				__spread_log(string($"Reloading table {_table_name_id}..."), SPREAD_MESSAGE_LEVEL.INFO);
				var _conn = global.Spread.connections[$ _metadata.source_connection];
				
				// Delete the previous directory as it's now based on SHA-1
				if (directory_exists(_conn.connection_cache_folder)) directory_destroy(_conn.connection_cache_folder);
				
				spread_connect_xlsx(_conn.connection_source, _metadata.source_connection, true);				
				spread_define_table(_table_name_id, _metadata.source_connection, _metadata.source_sheet, _metadata.source_range, _metadata.field_definition, _metadata.item_offset, _metadata.shape_is_rows, _metadata.error_on_schema_validation_fail, _metadata.item_validation_function, _metadata.table_validation_function, true);			
			}
			
		#endregion
				
		#region Getters and checkers
			
			/**
				* @desc	gets a value from a Spread table
				* @param	{string}	_key		key name
				* @param	{string}	_field		field name
				* @param	{string}	_table_id	table id
				* @return	{any}		the corresponding value
				*/			
			function spread_get(_key, _field, _table_id) {
				if (!struct_exists(global.Spread.tables, _table_id))							__spread_log($"Table {_table_id} is not defined", SPREAD_MESSAGE_LEVEL.ERROR);
				if (!struct_exists(global.Spread.tables[$ _table_id], _key))					__spread_log($"Key {_key} within table {_table_id} does not exist", SPREAD_MESSAGE_LEVEL.ERROR);
				if (!struct_exists(global.Spread.tables[$ _table_id][$ _key], _field))			__spread_log($"Field {_field} for key {_key} of table {_table_id} does not exist", SPREAD_MESSAGE_LEVEL.ERROR);
				return global.Spread.tables[$ _table_id][$ _key][$ _field];
			}
			
			/**
				* @desc	gets the struct corresponding to an item from a Spread table
				* @param	{string}	_key		key name
				* @param	{string}	_table_id	table id
				* @return	{struct}	the corresponding item
				*/			
			function spread_get_item(_key, _table_id) {
				if (!struct_exists(global.Spread.tables, _table_id))							__spread_log($"Table {_table_id} is not defined", SPREAD_MESSAGE_LEVEL.ERROR);
				if (!struct_exists(global.Spread.tables[$ _table_id], _key))					__spread_log($"Key {_key} within table {_table_id} does not exist", SPREAD_MESSAGE_LEVEL.ERROR);
				return global.Spread.tables[$ _table_id][$ _key];
			}
			
			/**
				* @desc	gets the struct corresponding to a Spread table
				* @param	{string}	_table_id	table id
				* @return	{struct}	the corresponding item
				*/			
			function spread_get_table(_table_id) {
				if (!struct_exists(global.Spread.tables, _table_id))							__spread_log($"Table {_table_id} is not defined", SPREAD_MESSAGE_LEVEL.ERROR);
				return global.Spread.tables[$ _table_id];
			}
			
			/**
				* @desc	gets the metadata struct corresponding to a Spread table
				* @param	{string}	_table_id	table id
				* @return	{struct}	the corresponding item
				*/			
			function spread_get_table_metadata(_table_id) {
				if (!struct_exists(global.Spread.tables, _table_id))							__spread_log($"Table {_table_id} is not defined", SPREAD_MESSAGE_LEVEL.ERROR);
				return global.Spread.table_metadata[$ _table_id];
			}
			
			/**
				* @desc	checks whether a key exists in a Spread table
				* @param	{string}	_key		key name
				* @param	{string}	_table_id	table id
				* @return	{boolean}	whether it exists or not
				*/			
			function spread_exists(_key, _table_id) {
				if (!struct_exists(global.Spread.tables, _table_id))							__spread_log($"Table {_table_id} is not defined", SPREAD_MESSAGE_LEVEL.ERROR);
				return struct_exists(global.Spread.tables[$ _table_id], _key);
			}
			
			/**
				* @desc	gets an array of item structs from a Spread table that meet a condition
				* @param	{string}			_table_id			table id
				* @param	{function}			[_where_condition]	a function that takes an item as a parameter and returns true or false. If not provided or undefined, it will get all keys.
				* @return	{array<string>}		the keys of the items that meet the condition
				*/			
			function spread_get_item_keys(_table_id, _where_condition=function(_elem) {return true;}) {
				if (!struct_exists(global.Spread.tables, _table_id))							__spread_log($"Table {_table_id} is not defined", SPREAD_MESSAGE_LEVEL.ERROR);
				if (!is_callable(_where_condition))												__spread_log($"Provided function must be callable", SPREAD_MESSAGE_LEVEL.ERROR);
				var _result = [];
				var _keys = struct_get_names(global.Spread.tables[$ _table_id]);
				for (var _i=0, _n=array_length(_keys); _i<_n; _i++) {
					var _key = _keys[_i];
					var _item = global.Spread.tables[$ _table_id][$ _key];
					if (_where_condition(_item))	array_push(_result, _key);
				}
				return _result;
			}
			
			/**
				* @desc	checks whether a table exists
				* @param	{string} _table_id	the table name
				* @returns {bool} whether it has been defined
				*/
			function spread_table_exists(_table_id) {
				return	struct_exists(global.Spread.tables, _table_id);
			}
			
			function spread_prod_mode() {
				return (!SPREAD_DEV_MODE || !SPREAD_ALLOW_DEV_MODE_OUTSIDE_IDE && GM_build_type == "exe" );
			}
				
		#endregion
			
	#endregion

#endregion


__spread_log($"Welcome to Spread, a spreadsheet-driven robust data pipeline for Gamemaker, by manta ray!", SPREAD_MESSAGE_LEVEL.SYSTEM);