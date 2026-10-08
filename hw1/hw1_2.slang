import hw1_common;

[shader("compute")]
[numthreads(8, 8, 1)]
void compute_main(uint2 tid : SV_DispatchThreadID,
                  StructuredBuffer<float2> polyline,
                  uniform int num_polyline,
                  uniform bool is_closed,
                  uniform bool use_fill_color,
                  uniform float3 fill_color,
                  uniform bool use_stroke_color,
                  uniform float3 stroke_color,
                  uniform float stroke_width,
                  RWTexture2D<float4> image) {
    uint width, height;
    image.GetDimensions(width, height);
    if (tid.x >= width || tid.y >= height) {
        return;
    }

    image[tid] = float4(1.0);
    // TODO: your code here    
    int numIntersects=0;
    for(int i=0;i<num_polyline;i++){
        float2 p0=polyline[i];
        float2 p1;
        if(i==num_polyline-1) {
            if(is_closed) {
                p1=polyline[0];
            }
        } else {
            p1=polyline[i+1];
        }
        float p0y=height-p0.y; //inversed height to match coordinate plane of hw
        float p1y=height-p1.y;
        float dx = p1.x - p0.x; //difference of x
        float dy = p1y - p0y; //difference of y
        float t=tid.y-(p0y);

        // nonzero algorithm
        if (p0y <=tid.y && tid.y < p1y) {
            t = t / (p1y-p0y);
            if ((p0.x+t*dx) >= tid.x) {
                numIntersects++;
            }
        }
        else if (p1y <= tid.y && tid.y < p0y) {
            t= t / (p1y-p0y);
            if ((p0.x+t*dx) >= tid.x) {
                numIntersects--;
            }
        }

        
        
        
    }

    if(numIntersects!=0 && use_fill_color){
        image[tid]=float4(fill_color,1.0);
    }

    for(int i=0;i<num_polyline;i++){
        
        if(i==num_polyline-1 && !is_closed) break;
        float2 p0=polyline[i];
        float2 p1;
        if(i==num_polyline-1) {
            if(is_closed) {
                p1=polyline[0];
            }
        } else {
            p1=polyline[i+1];
        }
        float p0y=height-p0.y; //inversed height to match coordinate plane of hw
        float p1y=height-p1.y;
        float l;
        float2 q=float2(tid.x, height-tid.y);
        float2 d = p1 - p0;
        float len = length(d);
        l=dot(d, q-p0) / len;
        float2 qprime=p0+l*d/len;
        if(l>0 && l<len && length(q-qprime) < stroke_width/2.0 && use_stroke_color) {
            image[tid]=float4(stroke_color, 1.0);
            
        }
        // round joins
        if(use_stroke_color && (is_closed || i!=0)) {
            if(length(q-p0) < stroke_width/2.0) {
                image[tid]=float4(stroke_color, 1.0);
            }
        }
    }
}
