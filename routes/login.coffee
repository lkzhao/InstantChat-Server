
express = require 'express'
jwt = require 'jsonwebtoken'

router = express.Router();

jwtSecret = process.env.JWT_SECRET

# POST /login
router.post '/', (req, res) ->
  # TODO: validate the actual user user
  profile =
    username: req.param("username"),
    first_name: 'John',
    last_name: 'Doe',
    email: 'john@doe.com',
    id: 123

  # we are sending the profile in the token
  token = jwt.sign profile, jwtSecret, { expiresInMinutes: 60*5 }

  res.json {token: token}

module.exports = router