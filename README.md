XML80020 Injector

Execute internal commands to operate with data values correspoing commands.
Commands applied to XML 80020 (80040) given as arguments to script.
Rollback any changes on fails.

CommandList:
  1. ADDFILL - Fill target value to selected hours by carry-over method
      Syntax "ADDFILL:XML_CLASS:AREA_CODE:MP_CODE:MAIN_CH_CODE:LINK_CH_CODE:TZ_CODE:HOUR_STRING:VALUE"
        * XML_CLASS     - 80020 or 80040 (if empty will ignore xml class);
        * AREA_CODE     - Area code given by ATS validation (can be empty);
        * MP_CODE       - Measuring point code by ATS validation;
        * MAIN_CH_CODE  - Measuring point main channel code (01, 02, 03, 04);
        * LINK_CH_CODE  - Measuring point linked channel code (01, 02, 03, 04) (can be empty);
        * TZ_CODE       - Trade zone code by ATS validation;
        * HOUR_STRING   - Mask to apply value. 24 or 48 seq of 0 or 1 (exmpl: 111111100000000000000111);
        * VALUE         - Value to apply (numeric int).
