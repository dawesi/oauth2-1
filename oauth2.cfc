<cfcomponent displayname="Oauth2" output="false">

<cfset variables.client_id = "">
<cfset variables.client_secret = "">
<cfset variables.redirect_uri = "">
<cfset variables.scope = "">
<cfset variables.state = "">
<cfset variables.access_type = "">
<cfset variables.approval_prompt = "">
<cfset variables.base_auth_endpoint = "">
<!--- Auth details from the authentication --->
<!---	access_token = "",
	refresh_token = "", --->
<cfset variables.token_struct = structNew()>

<cffunction name="GetTokenStruct" access="public" returntype="struct" output="false" hint="returns the oauth token structure">
	<cfreturn variables.token_struct>
</cffunction>

<cffunction name="IsAuth" access="public" returntype="boolean" output="false" hint="returns true if the access_token exists and has not expired">
	<!--- access token exists --->
	<cfif NOT StructKeyExists(getTokenStruct(), "access_token")>
		<cfreturn false>
	</cfif>

	<!--- expires_in exists --->
	<cfif NOT StructKeyExists(getTokenStruct(), "expires_in")>
		<cfreturn false>
	</cfif>

	<!--- see if the expires_in GT than now() --->
	<cfif dateCompare(now(), parseDateTime(getTokenStruct().expires_in), "n") GTE 0>
		<cfreturn false>
	</cfif>

	<cfreturn true>
</cffunction>

<cffunction name="IsRefresh" access="public" returntype="boolean" output="false" hint="returns whether a refresh token exists">
	<!--- access token exists --->
	<cfif NOT StructKeyExists(getTokenStruct(), "refresh_token")>
		<cfreturn false>
	</cfif>

	<cfreturn true>		
</cffunction>

<cffunction name="GetAccess_token" access="public" returntype="string" output="false" hint="getter for oauth access_token">
	<cfreturn getTokenStruct().access_token>
</cffunction>

<cffunction name="SetAccess_token" access="private" output="false" hint="setter for oauth access_token">
	<cfargument name="access_token" type="string" required="true">
	<cfset getTokenStruct()['access_token'] = arguments.access_token>
</cffunction>

<cffunction name="GetRefresh_token" access="public" returntype="string" output="false" hint="getter for oauth refresh_token">
	<cfreturn getTokenStruct().refresh_token>
</cffunction>

<cffunction name="SetRefresh_token" access="public" output="true" hint="setter for oauth refresh_token">
	<cfargument name="refresh_token" type="string" required="true">
	<cfset getTokenStruct()['refresh_token'] = arguments.refresh_token>
</cffunction>

<cffunction name="GetRedirect_uri" access="public" output="false" hint="getter for oauth redirect_uri">
	<cfreturn variables.redirect_uri>	
</cffunction>

<!--- end of token handling --->
<cffunction name="Init" access="public" output="false" hint="The constructor method.">
	<cfargument name="client_id" 		type="string" required="true"					hint="Indicates the client that is making the request. The value passed in this parameter must exactly match the value shown in the APIs Console." />
	<cfargument name="client_secret" 	type="string" required="true"					hint="The secret key associated with the client." />
	<cfargument name="redirect_uri" 	type="string" required="true"					hint="Determines where the response is sent. The value of this parameter must exactly match one of the values registered in the APIs Console (including the http or https schemes, case, and trailing '/')." />
	<cfargument name="scope" 			type="string" required="true"					hint="Indicates the Google API access your application is requesting. The values passed in this parameter inform the consent page shown to the user. There is an inverse relationship between the number of permissions requested and the likelihood of obtaining user consent." />
	<cfargument name="state" 			type="string" required="true"					hint="Indicates any state which may be useful to your application upon receipt of the response. The Google Authorization Server roundtrips this parameter, so your application receives the same value it sent. Possible uses include redirecting the user to the correct resource in your site, nonces, and cross-site-request-forgery mitigations." />
	<cfargument name="access_type" 		type="string" required="false" default="online" hint="ONLINE or OFFLINE. Indicates if your application needs to access a Google API when the user is not present at the browser. This parameter defaults to online. If your application needs to refresh access tokens when the user is not present at the browser, then use offline. This will result in your application obtaining a refresh token the first time your application exchanges an authorization code for a user." />
	<cfargument name="approval_prompt"	type="string" required="false" default="auto" 	hint="AUTO or FORCE. Indicates if the user should be re-prompted for consent. The default is auto, so a given user should only see the consent page for a given set of scopes the first time through the sequence. If the value is force, then the user sees a consent page even if they have previously given consent to your application for a given set of scopes." />
	<cfargument name="base_auth_endpoint"	type="string" required="false" default="https://accounts.google.com/o/oauth2/" 				hint="The base URL to which we will make the OAuth requests." />
	<cfargument name="token_storage" 	type="string" required="true" default="session"	hint="scope to store the tokens in (session, application)">
	
	<cfset variables.client_id = arguments.client_id>
	<cfset variables.client_secret = arguments.client_secret>
	<cfset variables.redirect_uri = arguments.redirect_uri>
	<cfset variables.scope = arguments.scope>
	<cfset variables.state =arguments.state>
	<cfset variables.access_type = arguments.access_type>
	<cfset variables.base_auth_endpoint = arguments.base_auth_endpoint>
	
	<cfset variables.token_storage = arguments.token_storage>

	<cfreturn this>
</cffunction>

<cffunction name="GetLoginURL" access="public" output="false" returntype="String" hint="I generate the link to login and retrieve the authentication code.">
	<cfset local.strLoginURL = variables.base_auth_endpoint 
 		 & "auth?scope=" & variables.scope
         & "&redirect_uri=" & variables.redirect_uri
         & "&response_type=code&client_id=" & variables.client_id
         & "&access_type=" & variables.access_type>
	<cfreturn local.strLoginURL>
</cffunction>
	
<cffunction name="GetAccessToken" access="public" output="false" returntype="Struct" hint="This method exchanges the authorization code for an access token and (where present) a refresh token.">
	<cfargument name="code" type="string" required="yes" hint="The returned authorization code.">

	<cfset local.strURL = variables.base_auth_endpoint & "token">
	<cfhttp url="#local.strURL#" method="post">
		<cfhttpparam name="code" 			type="formField" value="#arguments.code#">
		<cfhttpparam name="client_id" 		type="formField" value="#variables.client_id#">
		<cfhttpparam name="client_secret" 	type="formField" value="#variables.client_secret#">
		<cfhttpparam name="redirect_uri" 	type="formField" value="#variables.redirect_uri#">
		<cfhttpparam name="grant_type" 		type="formField" value="authorization_code">
	</cfhttp>

	<cfreturn manageResponse(cfhttp.FileContent)>

</cffunction>
	
<cffunction name="RefreshToken" access="public" output="false" hint="I take the refresh_token from the authorization procedure and get you a new access token.">
	<cfset var strURL = base_auth_endpoint & "token">

	<cfhttp url="#strURL#" method="POST">
   		<cfhttpparam name="client_id" 		type="formField" value="#variables.client_id#">
   		<cfhttpparam name="client_secret" 	type="formField" value="#variables.client_secret#">
   		<cfhttpparam name="refresh_token" 	type="formField" value="#getTokenStruct().refresh_token#">
   		<cfhttpparam name="grant_type" 		type="formField" value="refresh_token">
	</cfhttp>

	<cfreturn manageResponse(cfhttp.FileContent)>
</cffunction>
	
<cffunction name="ManageResponse" access="private" output="false" hint="I take the response from the access and refresh token requests and handle it.">
	<cfargument name="response" required="true" type="Any" hint="The response from the remote request." />
	
	<cfset var stuResponse 	= {}>
	<cfset var jsonResponse = deserializeJSON(arguments.response)>
	
	<cfif structKeyExists(jsonResponse, "access_token")>
		<!--- Insert the access token into the properties --->
		<cfset structInsert(stuResponse, "access_token",	jsonResponse.access_token)>
		<cfset structInsert(stuResponse, "token_type",		jsonResponse.token_type)>
		<cfset structInsert(stuResponse, "expires_in_raw",	jsonResponse.expires_in)>
		<cfset structInsert(stuResponse, "expires_in",		DateAdd("s", jsonResponse.expires_in, Now()))>
		
		<cfif structKeyExists(jsonResponse, "refresh_token")>
			<cfset structInsert(stuResponse, "refresh_token", jsonResponse.refresh_token)>
		</cfif>
		
		<cfset structInsert(stuResponse, "success", 		true)>
	<cfelse>
		<cfset structInsert(stuResponse, "access_token",	"Authorization Failed " & cfhttp.filecontent)>
		<cfset structInsert(stuResponse, "success", 		false)>
	</cfif>

	<cfset StructAppend(getTokenStruct(), stuResponse, true)>

	<cfreturn stuResponse>
</cffunction>
	
<cffunction name="RevokeAccess" access="public" output="false" hint="I revoke access to this application. You must pass in either the refresh token or access token.">
	<cfargument name="token" type="string" required="true" default="#getAccess_token()#" hint="The access token or refresh token generated from the successful OAuth authentication process." />

	<cfset var strURL = "https://accounts.google.com/o/oauth2/revoke?token=" & arguments.token>		
	<cfhttp url="#strURL#">

	<!--- delete token struct --->
	<cfset structClear(getTokenStruct())>

	<cfreturn cfhttp>
</cffunction>

<cffunction name="MakeRequest" access="private" returntype="Struct" hint="I make the actual request to the remote API.">
	<cfargument name="remoteURL" 	type="string" required="yes" hint="The generated remote URL for the request, including query string params. This does not include the access_token from the OAuth authentication process." />
	
	<cfset var authSubToken 	= 'Bearer ' & variables.access_token />
	<cfhttp url="#arguments.remoteURL#" method="get">
		<cfhttpparam name="Authorization" type="header" value="#authSubToken#">
	</cfhttp>
  	
	<cfreturn deserializeJSON(cfhttp.filecontent)>
</cffunction>

</cfcomponent>