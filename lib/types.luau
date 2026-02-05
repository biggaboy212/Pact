--!strict
export type TransportType = "TCP" | "UDP"

export type Schema<T> = {
    staticSize: number?, 
    
    size: (value: T) -> number,
    write: (b: buffer, offset: number, value: T) -> number,
    read: (b: buffer, offset: number) -> (T, number),
}

export type PacketDef<T> = {
    id: number,
    protocol: TransportType,
    schema: Schema<T>
}

return nil