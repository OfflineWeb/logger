/*
 * The MIT License
 *
 * Copyright 2017 papa.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package offlineweb.common.logger.aspects;

import offlineweb.common.logger.annotations.Loggable;
import org.aspectj.lang.JoinPoint;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * This aspect handles all logging. 
 * 
 * @author uditabose
 */
public aspect LoggerAspect {

    /**
     * Log Object Creation
     */
    static interface LogObject {
        Logger getLogger();
    }

    declare parents : (@Loggable *) implements LogObject;

    public Logger LogObject.getLogger() {
        return LogHolderAspect.aspectOf(this.getClass()).getLogger();
    }

    // loggable methods
    pointcut loggedMethod() : execution(@Loggable * *(..));

    // loggable method for exceoption handling
    pointcut loggedWithinMethod() : withincode(@Loggable * *(..));

    // loggable class
    pointcut loggedClass() : within(@Loggable *);

    // overridden object methods 
    pointcut objectMethods() : execution(public String *.toString()) ||
                               execution(public int *.hashCode())    ||
                               execution(public boolean *.equals());

    // all execution                          
    pointcut atExecution() : execution(* *(..));

    // at the start of the loggable methods
    before() : loggedMethod() && !objectMethods(){
        log(thisJoinPoint, "Begin");
    }

    // at the end of the loggable methods
    after() : loggedMethod() && !objectMethods(){
        log(thisJoinPoint,  "End");
    }

    // catch block of the loggable methods
    before (Throwable throwable): handler(Exception+) 
            && args(throwable) && loggedWithinMethod(){
        error(thisJoinPoint, throwable);
    }

    // at the start of the methods of loggable class
    before() : loggedClass() && atExecution() && !objectMethods(){
        log(thisJoinPoint, "Begin");
    }

    // at the end of the methods of loggable class
    after() : loggedClass() && atExecution() && !objectMethods(){
        log(thisJoinPoint,  "End");
    }

    // catch block of the methods of loggable class
    before (Throwable throwable): handler(Exception+) && args(throwable) && loggedClass(){
        error(thisJoinPoint, throwable);
    }

    //
    private void log(JoinPoint thisJoinPoint, String... prefix) {
        Logger logger = null;

        if (thisJoinPoint.getThis() instanceof LogObject) {
            logger = ((LogObject)thisJoinPoint.getThis()).getLogger();            
        } else {
            logger = LoggerFactory.getLogger(thisJoinPoint.getThis().getClass());
        } 
        
        if (prefix != null) {
            logger.info("{} # {}", prefix, unWrapJoinPoint(thisJoinPoint));
        } else {
            logger.info("{}", unWrapJoinPoint(thisJoinPoint));
        }
 
    }

    private void error(JoinPoint thisJoinPoint, Throwable throwable) {
        Logger logger = null;

        if (thisJoinPoint.getThis() instanceof LogObject) {
            logger = ((LogObject)thisJoinPoint.getThis()).getLogger();
        } else {
            logger = LoggerFactory.getLogger(thisJoinPoint.getThis().getClass()); 
        }

        logger.error("{} {}", unWrapJoinPoint(thisJoinPoint), throwable);
    }

    private StringBuilder unWrapJoinPoint(JoinPoint thisJoinPoint) {
        StringBuilder unWrappedJoinPoint = new StringBuilder();
        
        unWrappedJoinPoint.append(thisJoinPoint.getSourceLocation())
                          .append(":")
                          .append(thisJoinPoint.getSignature().getName())
                          .append("(");


        Object[] joinPointArgs = thisJoinPoint.getArgs();
        for (Object arg : joinPointArgs) {
            unWrappedJoinPoint.append(arg).append(":");
        }
        unWrappedJoinPoint.append(")");

        return unWrappedJoinPoint;
    }
}

