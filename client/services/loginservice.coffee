logger = new Logger("loginservice")
idSignIn = "login-signin-tab"
idSignup = "login-signup-tab"

findEmail = (t) ->
  return S.trim(null, t.find('.account-email').value)

findPassword = (t) ->
  return S.trim(null, t.find('.account-password').value)

class @LoginService
  setupTemplate: ->
    Template.login.helpers({
      showSignIn: ->
        return !Session.get("isInSignupMode")
      ,
      showSignUp: ->
        return !!Session.get("isInSignupMode")
      ,
    })
    Template.login.events({
      "click #login-signin-tab": ->
        if !Session.get("isInSignupMode")
          return

        logger.debug("Showing signin form")
        $("##{idSignIn}").addClass('active')
        $("##{idSignup}").removeClass('active')
        $("#signin-email").focus()
        # Display form corresponding to tab
        Session.set("isInSignupMode", false)
      "click #login-signup-tab": ->
        if Session.get("isInSignupMode")
          return

        $("##{idSignup}").addClass('active')
        $("##{idSignIn}").removeClass('active')
        $("#signup-email").focus()
        logger.debug("Showing signup form")
        Session.set("isInSignupMode", true)
      ,
      'submit #signin-form': (e, t) ->
        e.preventDefault()
        # retrieve the input field values
        email = findEmail(t)
        password = findPassword(t)

        Meteor.loginWithPassword(email, password, (err) ->
          if (err)
            notificationService.warn("Login Error", err.reason)
          else
            # The user has been logged in.
        )

        return false;
      ,
      'submit #signup-form': (e, t) ->
        errorCaption = "Signup Error"
        passwordLength = 8

        e.preventDefault()

        username = S.trim(null, t.find(".account-username").value)
        if S.isBlank(username)
          notificationService.warn(errorCaption, "You must supply a username")
          return false
        name = S.trim(null, t.find(".account-name").value)
        if S.isBlank(name)
          notificationService.warn(errorCaption, "You must supply a name")
          return false
        email = findEmail(t)
        password = findPassword(t)
        confirmedPassword = S.trim(null, t.find('.account-password-confirm').value)
        if password != confirmedPassword
          notificationService.warn(errorCaption, "Passwords don't match")
          return false

        if S.isBlank(password)
          notificationService.warn(errorCaption, "You must supply a password")
          return false
        if password.length < passwordLength
          notificationService.warn(errorCaption, "The password must consist of at least #{passwordLength} characters")
          return false

        logger.debug("Registering user #{email}")
        Accounts.createUser({
          username: username,
          email: email,
          password: password,
          profile: {
            name: name,
          },
        }, (err) ->
          if !err?
            logger.debug("User has been registered and logged in")
          else
            notificationService.warn(errorCaption, err.reason)
            logger.warn("Couldn't register user: #{err}")
        )

        Session.set("isInSignupMode", false)
        false
      ,
    })
    Template.forgotPassword.helpers({
      showRedirect: -> Session.get("isRedirecting")
      ,
      remainingSecondsString: ->
        seconds = Session.get("remainingSeconds")
        "#{seconds} second#{if seconds != 1 then "s" else ""}"
      ,
    })
    Template.forgotPassword.events({
      'submit #forgotpassword-form': (e, t) ->
        passwordLength = 8

        e.preventDefault()
        # Retrieve the input field values
        email = findEmail(t)
        logger.debug("Handling forgotten password for email #{email}")
        Accounts.forgotPassword({
          email: email,
        }, (err) ->
          if !err?
            logger.debug("Forgotten password has been handled for email #{email}")
            handleRedirect = ->
              if remainingSeconds == 0
                Session.set("isRedirecting", false)
                Router.go('/')
              else
                remainingSeconds -= 1
                Session.set("remainingSeconds", remainingSeconds)
                setTimeout(handleRedirect, 1000)

            remainingSeconds = 5
            Session.set("remainingSeconds", remainingSeconds)
            setTimeout(handleRedirect, 1000)
            Session.set("isRedirecting", true)
          else
            notificationService.warn("Error", err.reason)
            logger.warn("Couldn't handle forgotten password: #{err}")
        )

        return false
      ,
    })
