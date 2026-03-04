import { HTTP_STATUS } from '../config/constants.js';

export const validate = (schema, source = 'body') => {
  return (req, res, next) => {
    const input = req[source] ?? {};
    const { error, value } = schema.validate(input, {
      abortEarly: false
    });
    
    if (error) {
      const errors = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }));
      
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Validation failed',
        errors
      });
    }

    req[source] = value;
    
    next();
  };
};
