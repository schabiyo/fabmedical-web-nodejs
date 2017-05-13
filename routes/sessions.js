'use strict';

var express = require('express');
var dataAccess = require('../data-access');

var router = express.Router();

// get all
router.get('/', function(req, res, next) {
  dataAccess.getSessions(function (err, data, apiInstance) {
    if (err) {
      return next(err);
    }
    res.render('session-list', {
      title: 'The Conference Sessions',
      data: data,
      apiInstance : apiInstance
    });
  });
});

module.exports = router;
