//+------------------------------------------------------------------+
//|                                                   ZoloBridge.mqh |
//|                             Copyright 2000-2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2000-2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Send signal/message to ZOLO Bridge via WebRequest               |
//| Parameters:                                                      |
//|   message - The message/signal to send                          |
//|   enableWebRequest - Flag to enable/disable web requests        |
//|   url - The URL endpoint to send the request to                 |
//|   encryptionKey - Optional encryption key (not implemented)     |
//+------------------------------------------------------------------+
void SendSignalToBridge(string message, bool enableWebRequest, string url, string encryptionKey)
{
   // Check if web requests are enabled
   if(!enableWebRequest)
   {
      Print("ZoloBridge: Web requests are disabled");
      return;
   }
   
   // Validate URL
   if(StringLen(url) == 0)
   {
      Print("ZoloBridge: URL is empty, cannot send request");
      return;
   }
   
   // Validate message
   if(StringLen(message) == 0)
   {
      Print("ZoloBridge: Message is empty, nothing to send");
      return;
   }
   
   // Prepare data for POST request
   char post_data[];
   char result_data[];
   string result_headers;
   
   // Create JSON payload
   string json_payload = StringFormat("{\"message\":\"%s\",\"timestamp\":\"%s\",\"symbol\":\"%s\"}",
                                      message,
                                      TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
                                      Symbol());
   
   // Convert string to byte array
   StringToCharArray(json_payload, post_data, 0, WHOLE_ARRAY);
   ArrayResize(post_data, ArraySize(post_data) - 1); // Remove null terminator
   
   // Set request timeout (5 seconds)
   int timeout = 5000;
   
   // Perform the web request
   ResetLastError();
   int res = WebRequest(
      "POST",                    // Method
      url,                       // URL
      "Content-Type: application/json\r\n", // Headers
      timeout,                   // Timeout
      post_data,                 // Data to send
      result_data,               // Response data
      result_headers             // Response headers
   );
   
   // Check result
   if(res == -1)
   {
      int error_code = GetLastError();
      Print("ZoloBridge: WebRequest failed with error ", error_code);
      
      // Provide helpful error messages
      switch(error_code)
      {
         case 4014:
            Print("ZoloBridge: URL not allowed. Add '", url, "' to Tools->Options->Expert Advisors->Allow WebRequest for listed URL");
            break;
         case 4060:
            Print("ZoloBridge: Function not confirmed");
            break;
         case 5203:
            Print("ZoloBridge: Invalid URL");
            break;
         default:
            Print("ZoloBridge: Check MQL5 documentation for error code ", error_code);
      }
   }
   else if(res == 200)
   {
      // Success
      string response = CharArrayToString(result_data, 0, WHOLE_ARRAY);
      Print("ZoloBridge: Message sent successfully. Response: ", response);
   }
   else
   {
      // HTTP error
      string response = CharArrayToString(result_data, 0, WHOLE_ARRAY);
      Print("ZoloBridge: HTTP error ", res, ". Response: ", response);
   }
}

//+------------------------------------------------------------------+
//| Simple encryption function (placeholder)                         |
//| Note: For production use, implement proper encryption           |
//+------------------------------------------------------------------+
string EncryptMessage(string message, string key)
{
   // Placeholder for encryption functionality
   // In a real implementation, you would use proper encryption
   // For now, just return the original message
   if(StringLen(key) == 0)
      return message;
   
   // Simple XOR encryption (not secure, just a placeholder)
   string encrypted = "";
   int key_len = StringLen(key);
   
   for(int i = 0; i < StringLen(message); i++)
   {
      ushort msg_char = StringGetCharacter(message, i);
      ushort key_char = StringGetCharacter(key, i % key_len);
      ushort encrypted_char = msg_char ^ key_char;
      encrypted += ShortToString(encrypted_char);
   }
   
   return encrypted;
}
//+------------------------------------------------------------------+
