module tangled.failure;

import tango.core.Exception;

class Failure : Exception
{
    this( char[] msg )
    {
        super( msg );
    }

    /*    this( char[] msg, Exception e )
    {
        super( msg, e );
    }

    this( char[] msg, char[] file, size_t line )
    {
        super( msg, file, line );
    }
    */
}
