# Flutter plugins register through generated Android code. Keep annotations and
# generic signatures used by reflection while allowing R8 to shrink the rest.
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
